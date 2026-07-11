# 安全政策

LizzieYZY Mobile 处于 pre-alpha。当前可执行攻击面包括本地与系统交付的 SGF/GIB、应用私有持久化、相机/相册、图片解码与 ML Kit、系统分享，以及可配置的 KataGo WSS 客户端；尚无账户或项目运营的远端分析服务。输入已经有明确资源预算，但尚未完成模糊测试、独立安全审计和真机滥用矩阵，因此不要用预览构建处理高敏感私人数据或连接不受信任的 WSS 服务。

## 私密报告漏洞

不要在公开 issue、讨论区、社交媒体或 PR 中披露可利用细节。

1. 优先使用本仓库 **Security → Advisories → Report a vulnerability** 的私密入口。
2. 如果入口不可用，只创建标题为 `Security contact request` 的公开 issue，不附复现、日志、截图、密钥或样本；维护者会提供私密渠道。
3. 私密报告请包含受影响 commit/预览版本、平台、影响、最小复现、是否已公开和建议缓解方式。

不要上传真实令牌、私人棋谱、未脱敏照片、文件路径或第三方账户凭据。优先使用合成最小样本；需要传递敏感附件时，先等待维护者确认渠道和保留期限。

## 响应目标

- 3 个工作日内确认收到。
- 7 个工作日内给出初步分级与下一步。
- 高危问题优先进行私密修复、回归测试和协调披露。

这是响应目标而非服务等级保证。重复报告会合并；修复发布后会征得报告者同意再公开致谢。

## 当前支持范围

项目尚无稳定发布版。安全修复只针对 `main` 和维护者明确标记的最新预览版本；旧 commit、个人 fork、非官方二进制、自行替换模型和未合并分支不提供安全支持。

当前属于安全范围：

- 恶意 SGF/GIB 或图片导致的代码执行、越界访问、路径越权、持久拒绝服务或数据泄漏。
- 文件选择、临时文件、图片元数据或错误日志暴露用户路径和私人内容。
- 相机权限、后台采集、照片保留、临时拍照清理与 EXIF 泄漏。
- WSS 客户端的令牌泄漏、请求串线、取消失效、证书策略问题、恶意消息资源耗尽或跨请求数据暴露。
- 视觉/模型/更新清单的路径逃逸、哈希绕过或依赖供应链问题。
- 违反“静态局面不得获得完整棋谱/棋力”可信边界并造成数据或安全影响。

对应产品/下载代码落地后纳入范围：

- 桌面配对的认证绕过、跨设备请求伪造和长期配对令牌泄漏。
- 模型或更新下载中的来源、签名、大小和 SHA-256 校验绕过。

通常不属于安全漏洞：

- 仅影响候选质量或棋力区间、没有安全或隐私影响的数值差异。
- 已知不受信任输入上的一般 UI 错位。
- 需要已 root/jailbreak、关闭平台安全机制或物理解锁设备的攻击。
- 针对尚无代码路径功能的纯假设攻击；欢迎作为威胁建模 issue 提交，但不要标记为已存在漏洞。

## 当前实现事实

- SGF/GIB 只接受用户选择或系统以已登记 MIME 明确交付的 `.sgf/.gib`。原生导入执行 16 MiB、basename、有限任务队列、10 秒读取上限和可关闭句柄取消；Dart 层重复执行 16 MiB、严格文本解码与字符限制，解析器另限制树深、节点、属性和值长度。原生失败只回传无路径的类型化错误。每次用户明确打开都会送达；内容 SHA-256 去重只发生在持久化层，不会吞掉再次打开动作。结果按 `PositionSnapshot`、`PartialGameRecord`、`VerifiedGameRecord` 降级。
- 图片管线在解码前限制帧数、单帧/总编码字节、声明尺寸和像素数，解码后再次核对真实尺寸和像素预算；分析灰度平面与边缘点也有上限。这降低压缩炸弹和内存耗尽风险，但不替代 CPU 超时、原生解码器审计和模糊测试。
- 相机 runtime 延迟初始化、在非活动生命周期释放 controller、禁用音频、请求不带完整元数据的相册图片，并尝试删除临时拍照文件；清理失败不会阻止流程，因此发布前仍需设备级残留审计。
- ML Kit 输入图像和识别结果由 Google 声明为本机处理，但原生 SDK 会向 Google 发送设备/应用信息、安装标识、性能、API 配置、事件和错误等指标；供应链、隐私披露和 SDK 行为变化都属于安全审计范围。
- WSS provider 只接受 `wss://`，支持连接超时、Bearer header、request id 复用、取消和连接关闭。服务配置已进入产品设置，长期 token 使用 Keychain/Keystore；完整棋谱默认在每次远端发送前要求确认。
- 导入棋谱以内容 SHA-256 和双代索引持久化到应用私有目录；写入采用原子替换，损坏、哈希不符、孤儿或越界内容会降级/隔离。仓库没有账户数据库或默认云上传路径。
- 视觉基准校验脚本只读仓库文件，拒绝绝对路径、`..` 路径逃逸、未登记 PNG 和 SHA-256 不一致。
- 当前没有可发布的 KataGo/HumanSL 模型权重或生产棋力校准 artifact。

## 发布前安全闸门

- 为 SGF/GIB、系统导入和持久化边界加入覆盖解析器、原生通道、损坏索引和超时策略的持续模糊测试。
- 对图片预算、压缩炸弹、原生解码器、相机权限撤销、后台切换、低内存和临时文件残留进行多设备真机验证。
- 移除不需要的 EXIF；日志不得包含棋谱正文、照片路径、账户 ID、IP、令牌或设备标识。
- 对 WSS 入站消息、PV 长度、请求队列和整局耗时设置明确网络资源上限；验证 token 不进入日志、偏好、review bundle 或崩溃报告。
- 桌面配对使用一次性秘密、可撤销令牌、版本化协议和经过审查的证书策略。
- 模型、依赖和更新清单验证来源、许可、大小、版本、签名/哈希；失败时安全拒绝。
- 对每个候选版本生成并校验 SBOM、完整第三方许可文本、Apple 隐私报告和 Android Data Safety；依赖或数据流变化必须阻止未经复核的发布。

## English summary

Please use GitHub private vulnerability reporting. The pre-alpha build now has explicit SGF/GIB, native-inbound, image, persistence, and WSS message budgets; WSS tokens use install-scoped Keychain/Keystore storage and remote analysis requires a user-configured endpoint. No account or project-operated analysis service is shipped. Fuzzing, an independent security audit, physical-device camera retention review, production model/calibration validation, signed-candidate review, and store privacy audits remain release gates.
