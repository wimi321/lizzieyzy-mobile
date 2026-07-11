# 路线图

路线图按可验证退出条件推进，不承诺日期。勾选表示代码和测试已经存在，不表示商店发布质量。

## M0 · 视觉母版与单屏原型（当前）

状态：**核心实现完成，发布级验证继续补齐。**

- [x] Visual Benchmark v1：3 个方向、唯一 94 分北极星、10 张批准屏幕、实现证据和 SHA-256。
- [x] Flutter 浅/深主题与围棋设计系统组件。
- [x] 棋谱/识谱双入口、手机核心任务单屏模式切换和横屏平板扩展布局。
- [x] 360×800、375×667、393×852、412×915、430×932 单屏无纵向滚动回归测试。
- [x] 1.3×、2.0×、3.2×字号下核心页面与模式切换无裁切、无纵向滚动。
- [x] 三类 `KifuDocument`、规则校验和 provider 公共契约。
- [x] 固定 Flutter 3.41.6 的 Linux/Android 与 macOS/golden/iOS CI 配置。
- [ ] 扩大深色、伪本地化和 VoiceOver/TalkBack 真机覆盖。

退出条件：CI 在 GitHub 执行全绿；视觉变化可审查；文档不把在途 provider 写成现有能力。

## M1 · 棋谱核心与真实导入（进行中）

- [x] SGF FF[4] collection 语法解析，覆盖转义、节点、属性与变化。
- [x] SGF 围棋语义导入与确定性导出，保留未知属性、注释、setup stones 和变化。
- [x] 9/13/19 路、规则/贴目、Pass、让子 setup、损坏输入和可信类型降级测试。
- [x] 常见 GIB 元数据、棋步、让子、Pass、结果与警告的保守导入。
- [x] 系统文件选择、Android/iOS 打开与分享导入、导入状态和警告展示。
- [x] 内容 SHA-256、双代原子索引、损坏隔离的应用私有持久化，以及系统 SGF 分享导出。
- [ ] 不可变棋谱树编辑、撤销重做和跨版本数据迁移实测。
- [ ] OGS/野狐已完成棋局的只读导入及旧编码完整策略。

退出条件：批准棋谱集往返不丢节点、分支或未知属性；损坏输入有资源上限且不崩溃；非法手顺不生成 `VerifiedGameRecord`。

## M2 · 顶级复盘闭环（进行中）

- [x] `DefaultReviewBuilder`：输入完整性、关键手排序、阶段、走势、损失和候选命中率。
- [x] 数值复盘与棋力基础设施的 34 个定向测试。
- [x] KataGo Analysis JSON WSS provider：WSS-only 配置、整局请求、乱序归并、并发复用、三种胜率视角、取消和错误映射。
- [x] WSS 服务清单、产品设置、Keychain/Keystore token、逐次发送确认、应用作用域分析会话（离开分析页面后继续）、取消与失败重试。
- [x] 完整分析结果接入关键手、变化、走势、本局和 SGF 分享；静态局面与片段有独立降级页面。
- [x] 用户部署桌面桥：TLS-only WSS → KataGo Analysis JSONL、Bearer 鉴权、严格 App schema/计算预算、service/audit manifest 绑定、保留 KataGo 模型解析后缀的内容寻址私有 staging、进程回收和 27 项 Python 测试。
- [ ] 使用真实手机和用户桌面 GPU 完成证书/认证部署互操作、暂停/恢复、断网恢复和固定局面对照。
- [ ] 如发布策略需要，再实现原生本机 provider，并复用同一 contract tests。
- [ ] 版本化 Review Bundle，使手机与桌面能够无损接力。

退出条件：同模型同配置至少 10,000 个固定局面 Top-1 一致率达到 95%，`scoreLead` 中位差不超过 0.5 目；“打开棋谱 → 最大损失手 → 比较变化 → 回主线”成功率达到 95%。

## M3 · 拍照识谱（进行中）

- [x] 真实编码图片解码、方向归一和最小尺寸拒绝。
- [x] `GuideAlignedBoardVision` 19×19 导框识别实现与测试基线（可注入，当前 UI 未暴露自动失败后的切换入口）、3–7 帧概率融合和低置信校对数据。
- [x] 合成实体盘整盘、帧融合和损坏输入测试。
- [x] 实时相机/相册 runtime：延迟权限、后摄预览、闪光灯、三帧快门、单帧降级、生命周期和临时文件清理。
- [ ] 补齐权限拒绝/恢复、后台切换、低内存和多设备真机矩阵。
- [x] 有界自动四角/格线检测、9/13/19 路判型、单应透视、逐帧拉正融合、合成测试与类型化失败。
- [x] ML Kit Latin 数字候选、重复/错位拒绝，以及提子、同点复用、劫争和可信降级规则求解测试。
- [ ] 在产品纠错流程中提供自动检测失败后的显式导框入口，并完成多设备真机验证。
- [ ] 复杂光照、设备标定、反色/重叠数字、遮挡/反光与真实编号图覆盖。
- [ ] 发布授权数据说明、模型卡、设备基准与可复现评测脚本。

退出条件：独立测试集逐点准确率达到 99.8%，支持范围实体盘整盘完全正确率达到 95%，编号图完整手顺准确率达到 95%，非法 SGF 为 0。

## M4 · 单局棋力区间（基础设施完成，生产校准待做）

- [x] 只接受完整 19 路非让子棋，并排除 Pass 后要求至少 40 个有效决策。
- [x] manifest 驱动特征变换、连续 rank buckets、固定 80% 区间和版本模型 ID。
- [x] 分析 profile、逐节点 visits、模型 SHA-256 和 HumanSL 档位元数据约束。
- [x] 低/中置信度、策略概率下限、确定性和拒绝路径测试。
- [ ] 接入可分发的 HumanSL 多档策略、生产校准 artifact 与受控真实 KataGo 证据。
- [ ] 使用明确授权、按棋手隔离的数据训练并独立校准 20k–9d 模型。
- [ ] 发布模型卡、偏差分析、训练/留出集证明、模型哈希与 SBOM。

退出条件：留出集相邻宽等级组命中率达到 80%，标称 80% 区间实际覆盖率处于 75%–85%。在达标前，仓库算法不能被宣传为正式棋力评级。

## M5 · 发布硬化（进行中）

- [x] 简体中文、繁体中文、英语、日语、韩语资源和 30% 伪本地化生成/校验基线。
- [x] SGF/GIB、系统导入、持久化和图片字节/尺寸/像素资源上限。
- [x] iOS PrivacyInfo target、公开隐私政策、Android Data Safety 工作底稿和 ML Kit 数据/许可边界。
- [x] Pub/CocoaPods/Maven/Python CycloneDX SBOM、桌面桥锁文件/许可证/测试、许可/fixture guards，以及 Android/iOS 无签名 release-readiness workflow 配置；对应 job 是否通过以目标提交的 GitHub Actions 状态为准。
- [x] WSS 输入位置、visits、request id、并发、消息字节、JSON 复杂度、候选、响应条数和缓冲预算。
- [ ] VoiceOver、TalkBack、最大字号、减少动态、高对比和 Switch Access 真机验证。
- [ ] 解析/图片/WSS 持续模糊测试、渗透测试和候选版本隐私报告复核。
- [ ] 签名模型/更新清单、可复现签名构建和完整原生依赖 NOTICE 交付。
- [ ] 等待或替换具备原生 Apple Silicon iOS 26+ Simulator slice 的 Google ML Kit 上游二进制。
- [ ] iOS、Google Play、F-Droid 发布；中国大陆商店作为独立合规轨道。

## v1 明确不做

- 在线匹配对弈、直播、聊天室或社交动态。
- LLM 或自然语言棋评。
- 自动生成实战题、错题本或间隔重复训练。
- 永久棋力档案、跨局趋势或伪官方段位。
- 连续录像自动记谱。

## English summary

The project now includes bounded SGF/GIB import, private persistence and native file ingress, camera/gallery capture, automatic synthetic-tested 9/13/19 perspective detection, numbered-diagram evidence with strict rule solving, user-configured bounded WSS sessions, a hardened user-deployed desktop KataGo bridge, and real numeric review routes through sharing. These are code and test milestones, not claims of real phone-to-desktop GPU interoperability, independent recognition accuracy, physical-device accessibility/usability, controlled-service desktop parity, signed-store readiness, or production HumanSL calibration.
