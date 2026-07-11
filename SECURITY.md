# 安全政策

LizzieYZY Mobile 处于 pre-alpha。当前可执行攻击面已经包括本地 SGF/GIB、相机/相册、图片解码/分类和可配置的 KataGo WSS 客户端；尚无账户或项目运营的远端分析服务。不要把本仓库用于处理恶意超大文件、高敏感私人数据或不受信任的 WSS 服务。

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

- SGF/GIB 只在用户选择后读取，解析结果按 `PositionSnapshot`、`PartialGameRecord`、`VerifiedGameRecord` 降级。
- 图片在 isolate 中解码和分类，损坏与短边不足会被拒绝；这不等于已经具备压缩炸弹、超大尺寸或 CPU/内存配额防护。
- 相机 runtime 延迟初始化、在非活动生命周期释放 controller、禁用音频、请求不带完整元数据的相册图片，并尝试删除临时拍照文件；清理失败不会阻止流程，因此发布前仍需设备级残留审计。
- WSS provider 只接受 `wss://`，支持连接超时、Bearer header、按 request id 复用、取消和连接关闭；当前 token 由调用方直接提供，尚无产品级 Keychain/Keystore 配置层。
- 导入棋谱目前仅保存在进程内工作区；仓库尚无账户数据库或默认云上传路径。
- 视觉基准校验脚本只读仓库文件，拒绝绝对路径、`..` 路径逃逸、未登记 PNG 和 SHA-256 不一致。
- 当前没有可发布的 KataGo/HumanSL 模型权重或生产棋力校准 artifact。

## 发布前安全闸门

- 为 SGF/GIB 设置字节、树深、节点、属性和值长度上限，并加入模糊测试与超时。
- 在解码前限制图片字节、像素、帧数和内存预算；相机权限可撤销，原图保留由用户明确选择。
- 移除不需要的 EXIF；日志不得包含棋谱正文、照片路径、账户 ID、IP、令牌或设备标识。
- 所有远端分析使用 WSS；长期秘密进入 Keychain/Keystore，不写日志或明文设置。
- 桌面配对使用一次性秘密、可撤销令牌、版本化协议和经过审查的证书策略。
- 模型、依赖和更新清单验证来源、许可、大小、版本、签名/哈希；失败时安全拒绝。
- 发布 SBOM、完整第三方 notice、隐私说明和可复现的安全回归命令。

## English summary

Please use GitHub private vulnerability reporting. The active pre-alpha attack surface includes local SGF/GIB parsing, camera/gallery capture, image decoding, and a configurable KataGo WSS client; no account or project-operated remote-analysis service is shipped. Do not post exploits, credentials, private records, or original photos publicly. Parser/image resource limits, fuzzing, device-level camera-retention review, secure WSS credential storage, model verification, SBOM, and complete notices remain release gates.
