# 第三方依赖与通知

本文件记录当前直接 Dart/Flutter 依赖的许可摘要，便于开发审查。它不替代各上游包内的完整 `LICENSE`，也不是发布版 SBOM。实际解析版本以仓库的 `pubspec.lock` 为准；发布二进制前必须从锁文件重新生成包含传递依赖和平台组件的完整 notice。

## 当前直接运行时依赖

| 组件 | 当前锁定版本 | 用途 | 上游许可摘要 |
| --- | --- | --- | --- |
| Flutter SDK | 3.41.6 | 跨平台 UI 与构建工具链 | BSD-3-Clause；以 Flutter SDK `LICENSE` 为准 |
| `camera` | 0.12.0+1 | 后摄预览、拍照与闪光灯 runtime | BSD-3-Clause |
| `file_selector` | 1.1.0 | 本地 SGF/GIB 文件选择 | BSD-3-Clause |
| `image` | 4.9.1 | 图片解码、方向归一和交叉点取样 | MIT |
| `image_picker` | 1.2.3 | 相册图片选择 | BSD-3-Clause；上游包还携带平台组件 notice，必须一并保留 |
| `web_socket_channel` | 3.0.3 | KataGo Analysis JSON WSS provider | BSD-3-Clause |

开发依赖 `flutter_lints` 6.0.0 使用 BSD-3-Clause。Flutter SDK 自带的 Dart/测试包以及上述依赖的传递依赖没有逐项复制到本摘要；它们仍受各自上游许可证约束。

## 模型、数据与设计参考

- 当前仓库不分发 KataGo、HumanSL、OCR 或棋力校准模型权重。
- 测试中的模型 manifest、哈希、校准 buckets 和合成图片只是 fixture，不是生产模型或训练数据。
- `design/visual-benchmarks/` 是 imagegen 生成并登记哈希的屏幕设计参考，不会打包为运行时 UI。
- `design/brand/v1/` 记录 imagegen 图标候选、唯一入选源和哈希；入选图标会作为应用启动图标分发，Android 自适应/单色版本由仓库内矢量资源重建。
- 仓库没有额外捆绑全量 CJK 字体；运行时使用平台字体和 Flutter 自带资源。

引入模型或数据前，必须记录上游 URL、精确版本、SHA-256、SPDX 标识、修改/商用/再分发/应用商店权利、训练数据来源、隐私风险和模型卡。来源不明或仅限研究但不允许分发的内容不能进入发布构建。

## 发布要求

每个发布候选必须：

1. 从 `pubspec.lock` 和平台锁文件生成 SBOM。
2. 收集所有运行时及传递组件的完整许可证与 copyright notice。
3. 对比本文件，阻止未审查依赖、模型、字体或素材进入产物。
4. 在应用内或随安装包提供适合平台的第三方许可入口。
5. 对模型、数据和视觉清单分别验证签名或 SHA-256。

发现遗漏或许可变化时，请提交独立 PR，并附上游原始 `LICENSE` 证据；不要凭包主页标签猜测。

## English summary

This is a review-oriented summary of direct dependencies, not a complete binary notice or SBOM. Locked versions come from `pubspec.lock`; upstream package license files remain authoritative. Release artifacts must include all transitive and platform notices. No KataGo, HumanSL, OCR, or production calibration weights are currently distributed by this repository.
