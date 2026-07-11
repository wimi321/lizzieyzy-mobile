# 测试与验证

## 固定工具链

- Flutter 3.41.6 stable
- Dart 3.11.4（随上述 Flutter 提供）
- Android 构建使用 Java 17，当前 `minSdk` 为 API 29
- 桌面 KataGo 桥使用 Ubuntu 24.04 / Python 3.12；依赖只能从带 SHA-256 的 `requirements.lock` 安装
- macOS CI 与 release-readiness 均做 iOS 17 device `--release --no-codesign` 编译；不签名、不归档、不产生可发布安装包
- Apple Silicon iOS 26+ Simulator 组合因当前 Google ML Kit 二进制缺少对应 slice 而保留为上游外部门禁

Flutter patch 版本或宿主字体栈不同都可能造成 golden 漂移。视觉基线只在与 CI 相同的 macOS/Flutter 组合上审批。

## 提交前命令

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
python3 .github/scripts/verify_visual_benchmarks.py
python3 .github/scripts/verify_golden_font.py
python3 .github/scripts/verify_brand_assets.py
python3 .github/scripts/verify_privacy_declarations.py
python3 .github/scripts/verify_action_pins.py
python3 .github/scripts/verify_gradle_integrity.py
python3 .github/scripts/verify_release_workflows.py
python3 .github/scripts/verify_native_inbound_contract.py
python3 .github/scripts/verify_no_ui_fixture_imports.py
python3 .github/scripts/verify_design_token_usage.py
python3 tool/verify_licenses.py
python3.12 -m venv build/bridge-venv
build/bridge-venv/bin/python -m pip install --disable-pip-version-check \
  --require-hashes -r tool/katago_bridge/requirements.lock
build/bridge-venv/bin/python -m py_compile \
  tool/katago_bridge/*.py tool/katago_bridge/tests/*.py
PYTHONPATH=tool build/bridge-venv/bin/python -m unittest discover \
  -s tool/katago_bridge/tests -v
python3 -m unittest discover -s tool/tests -v
flutter test $(find test -type f -name '*_test.dart' ! -name 'golden_test.dart' -print | sort)
```

Golden 与平台构建：

```bash
flutter test test/golden_test.dart
flutter build apk --release --split-debug-info=build/symbols/android
.github/scripts/verify_android_permissions.sh \
  build/app/outputs/flutter-apk/app-release.apk
flutter build ios --release --no-codesign \
  --split-debug-info=build/symbols/ios
```

iOS 命令只能在安装兼容 Xcode 的 macOS 上运行。该命令只证明 device target 可以无签名编译；正式签名、安装真机和商店归档不属于当前 pre-alpha CI。

隐私门禁同时锁定 iOS `Info.plist` 的实际权限键、五种 `InfoPlist.strings` 文案、Xcode Runner target membership 与 `knownRegions`。iOS 构建完成后使用 `--app build/ios/iphoneos/Runner.app`，还会读取 Xcode 编译后的二进制 `.strings`，确保 en、zh-Hans、zh-Hant、ja、ko 五套权限文案真正进入候选包。

## 测试层次

| 层次 | 目录 | 当前验证内容 |
| --- | --- | --- |
| Domain | `test/domain/` | 坐标、规则、可信棋谱类型、识谱值对象、分析事件契约和测试 provider 行为 |
| Application | `test/application/` | 持久工作区、去重导入、设置/服务清单、应用级分析会话、真实取消/重试和旧结果失效 |
| Kifu infrastructure | `test/infrastructure/kifu/` | SGF 语法、语义导入、确定性导出、变化/未知属性往返、GIB 降级、原生错误 schema、initial 超时与重复显式打开 |
| Persistence/sharing | `test/infrastructure/persistence/`、`test/infrastructure/sharing/` | SHA-256 去重、双槽原子索引、重启/更新/删除、损坏隔离、SGF 系统分享、24 小时所有权清理、扫描/删除预算和失败安全 |
| Vision infrastructure | `test/infrastructure/vision/` | 真实图片解码、有界格线检测、9/13/19 路合成透视、单应拉正、移动帧融合、OCR 空间映射/冲突、损坏和资源上限 |
| Kifu sequence solving | `test/infrastructure/kifu/rule_checked_sequence_solver_test.dart` | 连续编号、重复/缺号、低置信、奇偶颜色、提子同点复用、劫和手数上限 |
| Analysis infrastructure | `test/infrastructure/analysis/` | WSS-only 配置、请求 JSON、视角归一、并发复用、取消、超时、消息/JSON/候选/缓冲预算和协议错误 |
| Desktop KataGo bridge | `tool/katago_bridge/tests/` | 27 项 Python 测试：临时 TLS WSS、Bearer、严格 App schema/计算预算、JSONL 透传、terminate 所有权、service/audit manifest 与 artifact 绑定、私有 staging、模型解析后缀、超时和进程清理 |
| Review infrastructure | `test/infrastructure/review/` | 34 个输入、数值、模型、区间、置信度和确定性测试 |
| Design system | `test/design_system/` | 主题、对比度、触控区、棋盘单节点语义、图表摘要、字号回流 |
| Feature flows | `test/features/` | 导入/保存、三类文档分流、拍照先入库后分析、真实分析 → 四个复盘区 → 分享、启动/恢复分享清理、关键手/平板/片段三条分享按钮的全局非零锚点、静态局面限制、360/375/393/412/430 单屏和平板扩展 |
| Accessibility | `test/accessibility/` | 1.3×、2.0×、3.2×字号、真实安全区、模式切换、触控区和完整语义 |
| App smoke | `test/widget_test.dart` | 真实应用入口与两项一级导航 |
| Golden | `test/golden_test.dart` | 393×852 手机与 1024×768 平板的批准 Flutter 渲染基线 |

新增 camera backend 或 KataGo provider 时，必须复用相同 contract tests，验证生命周期、取消、错误分类、模型清单、资源预算和数值语义，而不是只测试 happy path。相机 widget 测试注入测试平台以避免自动请求宿主权限；App WSS 测试使用进程内 WebSocket 双端，桌面桥集成测试使用临时自签名 TLS 和 fake KataGo，均不访问公网或真实 GPU。设计 fixture、合成棋盘和测试 provider 不进入运行时页面。

`.github/scripts/verify_native_inbound_contract.py` 额外锁定 Android/iOS 原生入口的 optional camera、MIME-only intent filter、有限队列、读取超时、无路径错误、iOS scene 重放和“显式重复打开不得被内容去重”边界；最终 APK guard 会再次解析合并后的 manifest，防止插件把相机 feature 恢复为 required。

自动视觉测试证明 9/13/19 路判型、透视与失败边界在受控合成输入上可执行，不构成真实照片准确率证据。单局棋力测试使用测试校准 manifest，只验证拒绝条件、特征变换、区间映射和确定性；没有生产 artifact 时，产品必须继续显示“暂不显示棋力区间”。

## 单屏回归

手机核心任务必须在 360×800、375×667、393×852、412×915 和 430×932 的安全区域内同屏完成：

- 页面不得用纵向 `ListView`、`SingleChildScrollView` 或隐蔽拖动承载主操作。
- 棋盘、当前决策和主要操作不能被底部导航或安全区遮挡。
- 更多数据通过有标签的模式切换呈现；切换后仍保持棋盘和当前手上下文。
- 测试需确认主按钮、关键数值和模式入口均命中同一视口，并在 `tester.takeException()` 中无溢出。
- 130%、200% 与 320%（最大系统字号近似）允许切换到专用密集模式，但不能缩小字体、缩小触控区、丢失可访问名称或退回纵向滚动。

单屏是一项任务约束，不是复制任何参考产品的布局。对阿Q围棋等公开产品只允许记录黑盒行为原则，不允许复用截图、资产或代码。

## 视觉清单验证

`.github/scripts/verify_visual_benchmarks.py` 是只读检查，执行以下门禁：

1. `manifest.json` 必须是 schema v1 的有效 JSON。
2. 北极星候选必须且只能有一个 `selected: true`，评分至少 90。
3. 所有候选、批准屏幕和实现证据必须有安全的相对 PNG 路径和小写 SHA-256。
4. manifest、`checksums.sha256` 与三个登记目录中的实际 PNG 文件集合必须完全相同。
5. 每个文件重新计算的 SHA-256 必须同时匹配 manifest 和 checksums。

该脚本不写 manifest、不更新哈希，也不把 AI 图当像素基线。

## Flutter golden

AI 生成母版只表达视觉意图；批准的 Flutter golden 才是机械像素回归源。Harness 固定 DPR、逻辑尺寸、`zh_CN`、字号、主题、动画和 ticker。更新流程：

1. 说明视觉变化的产品理由和受影响任务。
2. 在固定 macOS 环境生成 before、after 和 diff。
3. 先跑普通 widget、单屏和无障碍测试，不能用刷新 golden 掩盖溢出。
4. 非作者审查变化后再替换基线。

```bash
flutter test --update-goldens test/golden_test.dart
flutter test test/golden_test.dart
```

允许因安全区、无障碍、多语言、真实数据长度、平台惯例或性能偏离 imagegen 母版，但必须在 PR 中登记。

## 手工冒烟

发布候选至少覆盖：

- 375×667 小屏 iPhone 与一台大屏 iPhone。
- Android 360×800 与 412×915。
- iPad 和 Android 平板横竖屏。
- iPad 从关键手、横屏双栏复盘和片段棋谱分别调起分享；popover 必须锚定可见按钮，不得出现空矩形或越出当前视图。
- 字号 100%、130%、200% 与系统最大字号。
- VoiceOver、TalkBack、减少动态、高对比和 Switch Access。
- SGF/GIB 损坏、未知规则、缺手、setup、Pass、超大输入和取消文件选择。
- 图片损坏、过小、旋转、低置信、权限拒绝与内存压力。
- 实体盘 9/13/19 路、复杂光照、反光、遮挡、不同摄像头和真实编号图纠错。
- WSS 断网、超时、证书错误、取消、服务端错误、认证失效和模型哈希不匹配；必须覆盖真实手机 → 用户部署桌面桥 → 真实 KataGo GPU，而不只是在同机 fake engine 上通过。

棋盘必须继续作为单一二维语义控件，不能回退为 361 个读屏焦点。

以下发布结论不能由当前自动化测试推出，必须附独立证据：

- 识谱逐点 99.8%、实体盘整盘 95% 和编号图完整手顺 95% 的授权独立数据集报告。
- iPhone SE 2、Snapdragon 680 等目标设备的相机、内存、温度与帧耗时结果。
- VoiceOver、TalkBack、Switch Access、减少动态、高对比、SUS 和任务成功率真机记录。
- 真实手机与用户部署桌面 KataGo GPU 的受控互操作及至少 10,000 局面的桌面一致性对照。
- 生产 HumanSL/棋力校准的训练许可、棋手隔离留出集、覆盖率、模型卡与哈希。
- 签名包、商店账号、隐私表单、审核和目标市场合规。

## GitHub Actions

`.github/workflows/ci.yml` 固定 Flutter 3.41.6，并设置只读仓库权限、并发取消和超时：

- `quality`（Ubuntu）：格式、严格分析、非 golden 测试、视觉/隐私/可读 golden 字体、fixture import、产品 UI 语义设计 token、许可和锁文件 SBOM 门禁；Python 3.12 以 `--require-hashes` 安装桌面桥并执行 py_compile 与 27 项测试。
- `quality` 同时验证图标候选/源文件哈希、iOS 全尺寸、Android legacy/adaptive/monochrome 资源。
- `android-release`（Ubuntu + Java 17）：生成不启用 Dart obfuscation 的最终 release APK，针对该 APK 复跑许可与合并权限门禁，并强制保存 R8 mapping、AGP native symbols 和三个 Flutter AOT symbol map。
- `ios-device-and-golden`（macOS）：运行批准 golden 并编译无签名 iOS device release；不生成可安装签名包。
- `.github/workflows/release.yml`（tag/手动）：tag 必须精确等于 `v<pubspec version>`（含 build metadata；手动运行无 tag 时跳过），重复桌面桥锁定安装/测试与 macOS golden，构建 Android release 与 iOS device no-codesign，验证/归档 Android symbols 和全部 iOS dSYM UUID，并生成 Pub/CocoaPods/Maven/Python CycloneDX SBOM、完整许可、稳定 checksums 与确定性证据包。

所有 checkout 都禁用 `persist-credentials`。GitHub 对两个构建 job 的原始候选签发 build provenance；最终证据包使用单独的自定义 release-integrity predicate 签名，该 predicate 明确只覆盖摘要绑定和证据完整性，不冒充 SLSA build provenance。Gradle wrapper 的脚本、JAR、properties、distribution 摘要和可执行位由 `gradle-wrapper-integrity.json` 锁定。证据布局、符号恢复与独立验证命令见[发布候选与证据](RELEASE_EVIDENCE.md)。

以上项目描述工作流配置与预期门禁，不代表目标提交的 GitHub Actions job 已经通过；结论必须以对应公开 job 为准。当前 GoogleMLKit 9.x / MLKitVision 10.x 缺少 Apple Silicon iOS 26+ Simulator 所需的 `arm64-iphonesimulator` slice，因此该宿主组合下的 Simulator job 仍受上游二进制阻塞。单独通过的 iOS device `--no-codesign` 编译不能替代 Simulator job，也不能证明签名或商店发布就绪。

Linux 不执行 macOS golden，避免字体/渲染后端差异制造伪回归。任一必需任务失败都不得合并。

## English summary

CI workflows are pinned to Flutter 3.41.6 and are configured to run formatting, strict analysis, non-golden tests, visual/privacy/license/fixture guards, locked Python 3.12 desktop-bridge installation and tests, an Android release build with final-APK guards and retained crash symbols, macOS goldens, and an unsigned iOS device release compile. Sharing tests cover bounded and ownership-scoped 24-hour cache cleanup, startup/resume lifecycle behavior, and non-empty global anchors for key-move, tablet/iPad, and partial-record actions. Tag release-readiness requires an exact `v<pubspec version>` tag, reruns macOS goldens, retains UUID-verified dSYMs, and produces a deterministic evidence bundle with a custom digest-only integrity attestation. That custom claim is explicitly not SLSA build provenance. A configured job is not evidence that a specific commit passed; use the public GitHub Actions result. These checks do not claim real phone-to-desktop GPU interoperability, physical-device installation, signing, usability, or store-review completion.
