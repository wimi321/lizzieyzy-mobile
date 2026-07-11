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
- [x] 系统文件选择、导入状态、警告展示和进程内工作区。
- [ ] 不可变棋谱树编辑、撤销重做、分享导出和版本化持久化。
- [ ] OGS/野狐已完成棋局的只读导入及旧编码完整策略。

退出条件：批准棋谱集往返不丢节点、分支或未知属性；损坏输入有资源上限且不崩溃；非法手顺不生成 `VerifiedGameRecord`。

## M2 · 顶级复盘闭环（进行中）

- [x] `DefaultReviewBuilder`：输入完整性、关键手排序、阶段、走势、损失和候选命中率。
- [x] 数值复盘与棋力基础设施的 31 个定向测试。
- [x] KataGo Analysis JSON WSS provider：WSS-only 配置、整局请求、乱序归并、并发复用、三种胜率视角、取消和错误映射。
- [ ] 把 WSS provider 接入产品设置、凭据安全存储、真实服务、后台队列、暂停/恢复和失败重试。
- [ ] 再实现桌面配对或本机 provider，并复用同一 contract tests。
- [ ] 将关键手、变化、走势和本局页面从 fixture 接到真实 `ReviewReport`。
- [ ] 版本化 Review Bundle，使手机与桌面能够无损接力。

退出条件：同模型同配置至少 10,000 个固定局面 Top-1 一致率达到 95%，`scoreLead` 中位差不超过 0.5 目；“打开棋谱 → 最大损失手 → 比较变化 → 回主线”成功率达到 95%。

## M3 · 拍照识谱（进行中）

- [x] 真实编码图片解码、方向归一和最小尺寸拒绝。
- [x] 19×19 居中导框交叉点分类、3–7 帧概率融合和低置信校对数据。
- [x] 合成实体盘整盘、帧融合和损坏输入测试。
- [x] 实时相机/相册 runtime：延迟权限、后摄预览、闪光灯、三帧快门、单帧降级、生命周期和临时文件清理。
- [ ] 补齐权限拒绝/恢复、后台切换、低内存和多设备真机矩阵。
- [ ] 自动四角检测、透视矫正、9/13 路、复杂光照与设备标定。
- [ ] 编号棋谱 OCR、反色数字、Pass、提子和同点复用冲突求解。
- [ ] 发布授权数据说明、模型卡、设备基准与可复现评测脚本。

退出条件：独立测试集逐点准确率达到 99.8%，支持范围实体盘整盘完全正确率达到 95%，编号图完整手顺准确率达到 95%，非法 SGF 为 0。

## M4 · 单局棋力区间（基础设施完成，生产校准待做）

- [x] 只接受完整 19 路非让子棋，并排除 Pass 后要求至少 40 个有效决策。
- [x] manifest 驱动特征变换、连续 rank buckets、固定 80% 区间和版本模型 ID。
- [x] 分析 profile、逐节点 visits、模型 SHA-256 和 HumanSL 档位元数据约束。
- [x] 低/中置信度、策略概率下限、确定性和拒绝路径测试。
- [ ] 接入可分发的 HumanSL 多档策略与真实 KataGo 分析。
- [ ] 使用明确授权、按棋手隔离的数据训练并独立校准 20k–9d 模型。
- [ ] 发布模型卡、偏差分析、训练/留出集证明、模型哈希与 SBOM。

退出条件：留出集相邻宽等级组命中率达到 80%，标称 80% 区间实际覆盖率处于 75%–85%。在达标前，仓库算法不能被宣传为正式棋力评级。

## M5 · 发布硬化

- 简体中文、繁体中文、英语、日语、韩语与 30% 伪本地化。
- VoiceOver、TalkBack、最大字号、减少动态、高对比和 Switch Access 真机验证。
- 解析/图片/网络资源上限、模糊测试、隐私审计、SBOM 和完整依赖/模型 notice。
- 签名模型/更新清单、可复现构建与供应链审计。
- iOS、Google Play、F-Droid 发布；中国大陆商店作为独立合规轨道。

## v1 明确不做

- 在线匹配对弈、直播、聊天室或社交动态。
- LLM 或自然语言棋评。
- 自动生成实战题、错题本或间隔重复训练。
- 永久棋力档案、跨局趋势或伪官方段位。
- 连续录像自动记谱。

## English summary

The project has moved beyond a static UI prototype: SGF/GIB import, SGF export, file import, live camera/gallery capture, a real-image guide-aligned recognition baseline, a tested KataGo WSS provider, numeric review building, and the calibrated-estimator framework now exist. Product WSS/service wiring, robust perspective/OCR vision, production HumanSL calibration, persistent editing, and local/desktop KataGo providers remain active milestones.
