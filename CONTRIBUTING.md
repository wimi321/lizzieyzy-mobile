# 贡献指南

感谢你帮助 LizzieYZY Mobile 成为可靠、透明、真正适合手机的开源围棋复盘工具。项目处于 pre-alpha，但已包含真实 SGF/GIB codec、图像识别基线和数值复盘管线；贡献必须准确区分“已有实现”“在途接入”和“路线图目标”。

参与社区即表示你同意遵守 [行为准则](CODE_OF_CONDUCT.md)。提交代码前也必须阅读 [clean-room 与许可政策](docs/CLEAN_ROOM.md)。

## 开始之前

1. 搜索现有 issue 和 pull request，避免重复工作。
2. 对新功能、公共接口、依赖、模型、数据集或大范围视觉变更，先开 issue 说明方案。
3. 小型缺陷、测试补充、错别字和无行为变化的文档修正可以直接提交 PR。
4. 安全漏洞不要公开提交，按 [SECURITY.md](SECURITY.md) 报告。

## 开发环境

CI 固定 Flutter **3.41.6 stable**（Dart 3.11.4）。当前平台配置为 iOS 17.0+ 与 Android API 29+；Android 需要 Java 17，iOS 构建需要 macOS 和兼容 Xcode。

```bash
flutter --version
flutter pub get
flutter test
```

不要用 `flutter upgrade` 顺手更新工程元数据。升级 Flutter、Gradle、Xcode 设置或最低系统版本必须是单独 PR，并包含双平台验证。

## 分支与提交

- 从最新 `main` 创建短期分支，例如 `feature/sgf-parser` 或 `fix/board-semantics`。
- 一个 PR 解决一个清晰问题，避免混入格式化、依赖升级或无关重命名。
- 提交信息使用命令式、可搜索的描述；推荐 `feat:`, `fix:`, `test:`, `docs:`, `refactor:` 前缀，但不强制重写已有历史。
- 不提交密钥、真实账户令牌、未脱敏棋谱、个人照片、模型缓存或本机生成目录。

## 架构边界

- `lib/domain/` 是纯 Dart，不得导入 Flutter、平台插件、数据库或网络实现。
- feature 通过领域接口和 view model 获取数据，不直接访问 FFI、WebSocket、文件系统或相机。
- 三类 `KifuDocument` 是信任边界；不得用强制转换让照片局面进入完整棋谱或棋力评估。
- `lib/infrastructure/kifu/`、`vision/` 和 `review/` 实现领域契约，不得把平台状态或 UI 类型泄漏进 domain。
- UI 颜色、间距、圆角和动效优先使用 `lib/design_system/`；不要在 feature 创建平行设计系统。
- 棋盘读屏语义保持为一个二维可调控件；所有交互目标至少 48dp。
- 手机核心任务在 360×800、375×667、393×852 内使用明确模式切换，不得通过纵向滚动隐藏主操作。

架构变化必须同步 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 视觉变更

Visual Benchmark v1 是设计意图，不是运行时切图：

- 禁止把 `design/visual-benchmarks/` 的整屏图片或裁剪内容嵌入 App。
- 小型实现修正只需更新 Flutter 测试或 golden，不应重生成 imagegen 母版。
- 需要改变视觉方向时，PR 必须附原因、目标尺寸截图、无障碍影响和批准后的 manifest/hash 更新。
- 任何 golden 更新都要提供 before/after/diff，不能通过批量更新隐藏溢出或回归。

公开产品可以作为黑盒行为参考。例如，本项目只吸收阿Q围棋可观察到的“单屏模式切换”原则，不复制其排版、颜色、图标、文案、截图、协议或代码。PR 必须把参考原则与独立实现取舍写清楚。

## Clean-room 与来源

不得复制、翻译、机械改写、反编译或通过 AI 转换 LizzieYZY 桌面 GPL Java 源码及资产。允许基于公开标准、公开文档和黑盒行为独立实现兼容功能，但 PR 必须填写来源声明。

引入第三方依赖、模型或数据时，必须列出精确版本、上游 URL、许可证、分发权限和 SHA-256（适用时），并同步[第三方依赖与通知](docs/THIRD_PARTY_NOTICES.md)。没有许可证等同于没有分发许可。

## 测试

提交前至少运行：

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
python3 .github/scripts/verify_visual_benchmarks.py
flutter test $(find test -type f -name '*_test.dart' ! -name 'golden_test.dart' -print | sort)
```

批准的 macOS 环境还需运行：

```bash
flutter test test/golden_test.dart
```

修改平台代码时再运行：

```bash
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
```

测试应验证行为而不是实现细节。修复缺陷先增加可失败的回归测试；新增 provider 必须复用 contract tests；codec 需要损坏/降级/往返测试；图像管线需要合成像素与资源边界；数值算法需要固定 fixture、容差依据和非有限值测试。更多信息见 [测试指南](docs/TESTING.md)。

## Pull request 清单

PR 描述必须回答：

- 改了什么，为什么现在要改？
- 用户可见行为与失败/降级路径是什么？
- 运行了哪些命令和真机/模拟器检查？
- 是否影响无障碍、隐私、性能、模型或数据来源？
- 是否改变公共接口、持久化格式或网络协议？
- clean-room 来源与第三方许可证是否清楚？

维护者可能要求拆分 PR、补充测试、提供来源或删除无法重新分发的内容。CI 绿灯是合并必要条件，不代表自动获得合并资格。

## 文档与翻译

中文是当前主要维护语言；涉及用户界面或公共行为的文档应附简短英文摘要。翻译应保持“已完成、进行中、计划中”的状态差异，不能把目标路线图写成现有功能。

## 贡献许可

除非明确说明并经维护者同意，你提交的贡献将按仓库根目录 [MPL-2.0](LICENSE) 发布。你必须有权提交该内容，并承担提供准确来源信息的责任。

## English summary

Use Flutter 3.41.6, keep the domain layer pure Dart, reuse the design system, preserve the three-document trust boundary, and test every behavior change. Do not copy or transform GPL desktop source/assets. Document public specifications and third-party provenance, licenses, redistribution rights, and hashes. Run formatting, analysis, tests, and visual-manifest verification before opening a focused PR.
