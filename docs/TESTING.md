# 测试与验证

## 固定工具链

- Flutter 3.41.6 stable
- Dart 3.11.4（随上述 Flutter 提供）
- Android 构建使用 Java 17，当前 `minSdk` 为 API 29
- iOS CI 构建目标为 iOS 17.0 Simulator，不签名、不归档

Flutter patch 版本或宿主字体栈不同都可能造成 golden 漂移。视觉基线只在与 CI 相同的 macOS/Flutter 组合上审批。

## 提交前命令

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
python3 .github/scripts/verify_visual_benchmarks.py
python3 .github/scripts/verify_brand_assets.py
flutter test $(find test -type f -name '*_test.dart' ! -name 'golden_test.dart' -print | sort)
```

Golden 与平台构建：

```bash
flutter test test/golden_test.dart
flutter build apk --debug
.github/scripts/verify_android_permissions.sh
flutter build ios --simulator --debug --no-codesign
```

iOS 命令只能在安装兼容 Xcode 的 macOS 上运行。正式签名、真机构建和商店归档不属于当前 pre-alpha CI。

## 测试层次

| 层次 | 目录 | 当前验证内容 |
| --- | --- | --- |
| Domain | `test/domain/` | 坐标、规则、可信棋谱类型、识谱值对象、分析契约、fake provider |
| Kifu infrastructure | `test/infrastructure/kifu/` | SGF 语法、语义导入、确定性导出、变化/未知属性往返、GIB 降级 |
| Vision infrastructure | `test/infrastructure/vision/` | 真实图片解码、19 路合成交叉点、帧融合、损坏与过小输入 |
| Analysis infrastructure | `test/infrastructure/analysis/` | WSS-only 配置、请求 JSON、视角归一、并发复用、取消、超时和协议错误 |
| Review infrastructure | `test/infrastructure/review/` | 31 个输入、数值、模型、区间、置信度和确定性测试 |
| Design system | `test/design_system/` | 主题、对比度、触控区、棋盘单节点语义、图表摘要、字号回流 |
| Feature flows | `test/features/` | 导入状态、静态局面限制、360/375/393/412/430 单屏、复盘模式切换、平板扩展 |
| Accessibility | `test/accessibility/` | 1.3×、2.0×、3.2×字号、真实安全区、模式切换、触控区和完整语义 |
| App smoke | `test/widget_test.dart` | 真实应用入口与两项一级导航 |
| Golden | `test/golden_test.dart` | 393×852 手机与 1024×768 平板的批准 Flutter 渲染基线 |

新增 camera backend 或 KataGo provider 时，必须复用相同 contract tests，验证生命周期、取消、错误分类、模型清单和数值语义，而不是只测试 happy path。现有相机页面用注入 fake 避免 widget test 触发权限，WSS 测试使用内存 WebSocket 双端，不访问公网。

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
- 字号 100%、130%、200% 与系统最大字号。
- VoiceOver、TalkBack、减少动态、高对比和 Switch Access。
- SGF/GIB 损坏、未知规则、缺手、setup、Pass、超大输入和取消文件选择。
- 图片损坏、过小、旋转、低置信、权限拒绝与内存压力。
- WSS 断网、超时、证书错误、取消、服务端错误和模型哈希不匹配（连接真实服务前）。

棋盘必须继续作为单一二维语义控件，不能回退为 361 个读屏焦点。

## GitHub Actions

`.github/workflows/ci.yml` 固定 Flutter 3.41.6，并设置只读仓库权限、并发取消和超时：

- `quality`（Ubuntu）：格式、严格分析、非 golden 测试和视觉清单完整性。
- `quality` 同时验证图标候选/源文件哈希、iOS 全尺寸、Android legacy/adaptive/monochrome 资源。
- `android-debug`（Ubuntu + Java 17）：生成 debug APK。
- `ios-simulator-and-golden`（macOS）：运行批准 golden 并构建无签名 iOS Simulator app。

Linux 不执行 macOS golden，避免字体/渲染后端差异制造伪回归。任一必需任务失败都不得合并。

## English summary

CI is pinned to Flutter 3.41.6. Ubuntu runs formatting, strict analysis, all non-golden tests, read-only visual-manifest verification, and an Android debug build. macOS owns deterministic Flutter goldens and the unsigned iOS Simulator build. Tests cover SGF/GIB codecs, camera UI through injected fakes, real-image guide recognition, the KataGo WSS protocol, 31 numeric review/performance cases, one-viewport phone flows across five reference sizes, and 1.3×/2.0×/3.2× accessibility text modes.
