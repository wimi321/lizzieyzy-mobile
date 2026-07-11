# 第三方依赖与通知

本文件是当前直接依赖和重要原生边界的人工审查摘要。精确解析版本以 `pubspec.lock`、`ios/Podfile.lock`、Android release runtime graph 和 `tool/katago_bridge/requirements.lock` 为准；它不替代上游完整许可证、自动生成的 CycloneDX SBOM 或发布产物中的完整许可文本。

## 仅测试使用的 golden 字体

`test/assets/LizzieYzyGoldenCjk.otf` 是 Noto Sans CJK SC 2.004 的重命名、
裁剪版本，仅用于让 Flutter golden 中的中文可以人工审查。上游字体由
Noto 项目按 SIL Open Font License 1.1 发布，完整许可保存在
`test/assets/OFL-LICENSE.txt`；生成脚本固定并核验上游 SHA-256。该字体未在
`pubspec.yaml` 中声明，不会进入 iOS 或 Android 应用包。

## 直接运行时依赖

| 组件 | 锁定版本 | 用途 | SPDX/许可边界 |
| --- | --- | --- | --- |
| Flutter SDK（含 `flutter_localizations`） | 3.41.6 | UI、平台嵌入与本地化 | BSD-3-Clause；以 Flutter SDK `LICENSE` 为准 |
| `big5_utf8_converter` | 1.2.0 | Big5 棋谱文本严格解码/编码 | MIT |
| `camera` | 0.12.0+1 | 后摄预览、拍照与闪光灯 | BSD-3-Clause |
| `charset` | 2.0.1 | GBK 棋谱文本严格解码/编码 | Apache-2.0 |
| `cp949_codec` | 1.0.2 | CP949 棋谱文本严格解码/编码 | BSD-3-Clause |
| `crypto` | 3.0.7 | 内容 SHA-256 | BSD-3-Clause |
| `file_selector` | 1.1.0 | 本地 SGF/GIB 和服务清单选择 | BSD-3-Clause |
| `flutter_secure_storage` | 10.3.1 | Keychain/Keystore token 存储 | BSD-3-Clause；还包含平台实现包 |
| `google_mlkit_text_recognition` | 0.16.0 | 调用原生 ML Kit 的 Flutter 平台通道桥 | MIT；**不覆盖 Google 原生 ML Kit SDK** |
| `image` | 4.9.1 | 图片解码、方向归一和棋盘取样 | MIT |
| `image_picker` | 1.2.3 | 用户选择相册图片 | BSD-3-Clause AND Apache-2.0；上游 `LICENSE` 同时携带平台组件通知 |
| `intl` | 0.20.2 | 本地化运行时 | BSD-3-Clause |
| `path_provider` | 2.1.6 | 应用私有持久化与临时目录 | BSD-3-Clause |
| `share_plus` | 13.2.0 | 系统 SGF 分享面板 | BSD-3-Clause |
| `shared_preferences` | 2.5.5 | 非敏感应用设置 | BSD-3-Clause |
| `web_socket_channel` | 3.0.3 | KataGo Analysis JSON WSS 客户端 | BSD-3-Clause |

开发依赖 `flutter_lints` 6.0.0 使用 BSD-3-Clause。Flutter/Dart 测试工具和上述包的传递依赖会进入锁文件与开发 SBOM；发布 SBOM 必须把仅开发依赖标为 excluded，避免将其误写成运行时组件。

## WHATWG GB18030 范围数据

`lib/infrastructure/kifu/kifu_text_decoder.dart` 为完整 GB18030 四字节往返编码嵌入了 WHATWG Encoding Standard 的 `index-gb18030-ranges.txt`（2024-09-18，identifier `f963aaa1653f630c523e7b04729fb4e4458f35806c45eb5c179445623138f0c0`）。Copyright © WHATWG（Apple、Google、Mozilla、Microsoft）。该标准整体采用 CC BY 4.0；其中纳入源代码的部分按 BSD-3-Clause 授权。本仓库把这组范围数据作为源代码纳入，并按 BSD-3-Clause 使用。来源与知识产权声明分别见 [范围数据](https://encoding.spec.whatwg.org/index-gb18030-ranges.txt)和 [Encoding Standard](https://encoding.spec.whatwg.org/#ipr)。

## 用户部署桌面桥依赖

下列 Python 组件仅供 `tool/katago_bridge/` 使用，标记为用户部署的可选桌面工具，不会进入 iOS 或 Android 二进制：

| 组件 | 锁定版本 | 用途 | SPDX/许可边界 |
| --- | --- | --- | --- |
| `websockets` | 16.0 | TLS WSS 服务端与 KataGo JSONL 桥接 | BSD-3-Clause |

`requirements.lock` 固定 python-websockets 发布的通用 `py3-none-any` wheel 直接 URL 与 SHA-256 `1637db62fad1dc833276dded54215f2c7fa46912301a24bd94d45d46a011ceec`；CI 使用 `pip --require-hashes` 安装。审查过的许可证原文位于 `tool/katago_bridge/LICENSES/websockets-BSD-3-Clause.txt`，SBOM 同时记录 wheel 与许可证文本哈希。任何新增 Python 包、平台 wheel、版本、URL、哈希或许可证变化都必须先更新人工政策，未审查项会 fail-closed。

## Google ML Kit 与 Flutter 插件边界

`google_mlkit_text_recognition` 和 `google_mlkit_commons` 是 `flutter-ml.dev` 维护的 MIT Flutter 插件，不由 Google 赞助或维护。插件把请求通过平台通道交给闭源/单独授权的 Google 原生 SDK：

- Android：至少包含 `com.google.mlkit:text-recognition:16.0.1` 和其 runtime 依赖。
- iOS：`GoogleMLKit/TextRecognition` 9.x 与 `MLKitVision` 10.x，精确版本以 `Podfile.lock` 为准。

插件的 MIT 许可不授予 Google ML Kit 二进制或模型的再许可权。使用原生 SDK 还受 [ML Kit Terms & Privacy](https://developers.google.com/ml-kit/terms)及其纳入的 Google APIs 条款约束；不得把这些组件宣传为本仓库的 MPL-2.0 代码，也不得逆向或提取其模型，除非适用法律明确允许。

Google 声明 ML Kit 输入图像和识别结果在设备上处理，但 SDK 会向 Google 发送设备/应用信息、安装标识、性能、API 配置、事件与错误等指标。发布者必须同步更新 [隐私政策](../PRIVACY.md)、[Android Data Safety 工作底稿](ANDROID_DATA_SAFETY.md)和 Apple 隐私标签，不能因 Flutter 插件本身是 MIT 就忽略原生 SDK 的条款与数据行为。

## 平台插件与原生组件

- `camera`、`file_selector`、`image_picker`、`path_provider`、`share_plus`、`shared_preferences` 和 `flutter_secure_storage` 会解析为平台实现包、Android AAR/Maven 组件或 iOS Pods。
- iOS 构建生成的 Pods acknowledgements 必须随候选版本审查；Android Maven 传递组件必须出现在 SBOM 和完整许可文本中。
- Android Jetpack、CameraX、Kotlin/AndroidX 等常见组件通常使用 Apache-2.0，但不得凭名称推断；以候选构建解析到的 POM/许可证为准。
- 当前仓库不分发 KataGo、HumanSL、OCR 自有模型或正式棋力校准权重。远端服务清单中的模型元数据不是可再分发模型许可。
- 桌面桥只提供协议与进程边界，不捆绑 KataGo 引擎、配置、normal/HumanSL 模型、TLS 私钥或 token；这些用户提供的 artifact 必须独立核对来源和许可。

## 模型、数据与视觉参考

- 测试中的 manifest、哈希、校准 buckets、棋谱和合成图片是 fixture，不是生产模型或训练数据。
- `design/visual-benchmarks/` 是已登记哈希的设计参考，不作为运行时整屏切图。
- `design/brand/v1/` 保存图标生成来源和哈希；入选图标作为应用图标分发。
- 仓库不捆绑额外全量 CJK 字体，运行时使用平台字体和 Flutter 资源。

引入模型或数据前，必须记录上游 URL、精确版本、SHA-256、SPDX/专有条款、修改和分发权、商店权利、训练数据来源、隐私风险及模型卡。来源不明或仅允许研究但不允许分发的内容不得进入发布构建。

## 发布要求

每个发布候选必须：

1. 从 Pub/CocoaPods/Python 锁文件和 Android release runtime graph 生成并校验 CycloneDX SBOM。
2. 运行许可检查，为所有解析到的 hosted Dart 包和桌面桥 Python 包生成完整许可文本产物。
3. 收集 CocoaPods acknowledgements、Android Maven 许可证及所有 copyright/NOTICE。
4. 对比本文件，阻止未审查的依赖、模型、字体或素材进入产物。
5. 在应用内或随安装包提供适合平台的第三方许可入口。
6. 对模型、数据、视觉和更新清单分别验证来源、大小、版本和 SHA-256/签名。

发现遗漏或许可变化时，应提交独立审查并附上游原始许可证证据；不要凭包主页标签、仓库主题或依赖名称猜测。

## English summary

This file is a human-reviewed summary, not the complete binary notice or SBOM. The MIT-licensed `flutter-ml.dev` plugin is only a bridge; Google ML Kit native binaries and models remain subject to Google ML Kit and Google APIs terms and have separate privacy behavior. The optional user-deployed desktop bridge pins the universal `websockets 16.0` wheel by URL and SHA-256 and does not ship in either mobile binary. Release evidence inventories Pub, CocoaPods, Maven, and Python components, preserves complete license/NOTICE texts, and keeps store privacy disclosures aligned with the exact shipped SDK graph.
