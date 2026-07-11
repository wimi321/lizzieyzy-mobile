# Clean-room 与许可政策

LizzieYZY Mobile 采用 Mozilla Public License 2.0（MPL-2.0），与 GPLv3 的 LizzieYZY 桌面代码库独立开发。本政策的目的，是让兼容行为有据可查，同时避免把无权重新许可的代码、资源、模型或数据带入移动仓库。

> 本文是工程贡献政策，不构成法律意见。来源或许可不明确时，不要提交；先在 issue 或 draft PR 中请求审查。

## 基本规则

### 可以做

- 阅读公开产品文档、协议规范、论文和公开 UI 行为，编写需求与黑盒测试。
- 通过运行公开发布版观察输入输出，并以独立数据结构重新实现兼容行为。
- 记录公开产品的高层交互原则，例如“手机单屏内通过有标签模式切换”，再用本仓库 tokens 和组件独立设计。
- 参考标准格式，例如 SGF FF[4]、GTP 和 KataGo Analysis JSON 的公开文档。
- 在 PR 中链接公开来源、记录行为差异和独立设计取舍。
- 对 MPL-2.0 兼容的第三方代码按其许可与 notice 要求使用。

### 不可以做

- 复制、翻译、机械改写或逐行对应桌面版 GPL Java 源码。
- 复制桌面 UI 图片、图标、字体、音频、测试数据或其他资产，除非其许可明确允许并经过审查。
- 复刻阿Q围棋或其他移动产品的页面排版、配色、文案、截图、切图、协议或代码；黑盒参考不等于视觉复制许可。
- 把 GPL 代码经由生成器、反编译器、AI 改写或语言转换后提交；改变表达形式不会自动改变来源义务。
- 提交来源不明的 KataGo/HumanSL 权重、训练数据、棋谱集、OCR 字体集或照片。
- 通过私有平台协议绕过访问控制、抓取限制或服务条款。

## 推荐实现流程

1. **规格人员**记录公开来源、可观察行为、输入/输出样例和边界条件，不提供桌面源码片段。
2. **实现人员**仅根据规格、公开标准和本仓库领域接口编写移动端代码。
3. **验证人员**使用独立 fixture 或黑盒输出比较行为，不使用复制来的内部测试。
4. PR 在 `Clean-room / provenance` 小节声明来源、是否查看过相关 GPL 文件、第三方资产及许可证。

小型团队无法总是进行完全人员隔离，但仍必须做到：不粘贴源代码、不做逐行翻译、保留公开依据、让审阅者能解释独立设计。

## MPL-2.0 在本仓库中的含义

- 修改 MPL 覆盖的源文件并分发时，该文件的源代码仍需按 MPL-2.0 提供。
- MPL 是文件级 copyleft；可以与不同许可的更大作品组合，但必须遵守每个组件的许可。
- MPL 不授予项目名称、Logo 或第三方素材的商标权。
- 新文件默认按仓库根目录 `LICENSE` 的 MPL-2.0 发布，除非文件和 PR 清楚标明其他兼容许可并经维护者批准。
- 二进制分发必须向接收者说明如何取得相应 MPL 源代码。

完整法律文本以 [LICENSE](../LICENSE) 为准。

## 桌面桥接边界

- 移动端协议、数据类型和客户端代码保留在本 MPL 仓库。
- 如果为配对功能修改 LizzieYZY 桌面版，这些修改在桌面 GPL 仓库中完成并按 GPL 发布。
- 两端通过版本化、公开记录的网络协议通信；不得把桌面源文件复制进移动构建。

## 依赖、模型与数据

引入任何依赖、模型或数据集，PR 必须记录：

- 名称、精确版本、上游 URL 和 SHA-256（适用时）。
- SPDX 许可证标识或完整许可文本。
- 是否允许修改、重新分发、商用和应用商店分发。
- 模型的训练数据来源、模型卡和导出/量化过程。
- 数据中的隐私、未成年人、人脸、地理位置与棋手账户风险。

不接受“网上找到”“仅研究用途但用于发布”“上游没有写许可证”作为可分发依据。

## 视觉母版

`design/visual-benchmarks/` 是经过登记的设计参考，不是运行时资产。实现只能提炼层级、颜色、密度和交互，不能把整屏 PNG 或裁剪片段嵌进 UI。更换母版必须同步 prompt/provenance、manifest 和 SHA-256，并通过设计审查。

阿Q围棋等公开产品只可贡献可观察的任务原则。当前登记的参考原则是“手机核心任务单屏呈现，以明确模式切换替代向下堆叠”；实现必须使用 LizzieYZY Mobile 自己的信息架构、视觉母版、设计系统和测试，PR 不得附带或提交对方截图/资产。

## PR 来源声明模板

```text
Clean-room / provenance
- Public specifications consulted:
- Related GPL source viewed by implementer: yes / no
- Why this implementation is independent:
- Third-party code/assets/models/data:
- Licenses and hashes verified:
```

## English summary

This MPL-2.0 mobile repository is developed independently from the GPLv3 desktop repository. Do not copy, translate, mechanically rewrite, decompile, or AI-transform desktop source or assets. Compatible behavior may be implemented from public specifications and black-box observations with documented provenance. Public apps may inform high-level interaction principles such as single-viewport mode switching, but their visual layout, copy, assets, protocols, and code must not be copied. Every dependency, model, and dataset needs an explicit redistributable license and, where applicable, a reproducible hash.
