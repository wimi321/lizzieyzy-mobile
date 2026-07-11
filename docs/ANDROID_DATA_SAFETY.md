# Android Data Safety 发布工作底稿

审计日期：2026-07-11

应用 ID：`com.wimi321.lizzieyzy.mobile`

这是根据当前源码和锁定依赖生成的保守发布工作底稿，不会自动提交 Google Play 表单。发行负责人必须对最终 AAB、启用的功能、发行地区、远端服务运营者和当时的 Google Play 问卷重新审计；不能把本文件原样当成法律结论。

## 建议的顶层回答

| Play Console 问题 | 当前保守答案 | 依据 |
| --- | --- | --- |
| 应用是否收集或分享用户数据 | **是** | ML Kit 会把 SDK 诊断和使用指标传给 Google；可选 WSS 分析会把完整棋谱传给用户配置的服务 |
| 所有设备外传输是否加密 | **是，但必须用最终 AAB 复核** | ML Kit 声明指标使用 HTTPS；应用只允许 `wss://` 分析端点 |
| 是否有账号创建 | **否** | 当前没有账号系统 |
| 是否可请求删除数据 | **不要勾选，除非发行主体建立并验证请求机制** | 本地数据可通过清除应用数据/卸载删除；第三方 WSS 与 Google SDK 指标不由应用直接控制 |
| 是否面向儿童 | **否** | 当前产品定位不是儿童专用应用；若商店受众选择变化必须重审 |

Google Play 把“收集”定义为把数据传出设备，并要求把 SDK 的行为计算在应用内；仅在设备上访问的数据不构成收集。参见 [Data safety 表单说明](https://support.google.com/googleplay/android-developer/answer/10787469)和 [User Data 政策](https://support.google.com/googleplay/android-developer/answer/10144311)。

## 数据类型映射草案

| Play 数据类型候选 | 收集方式 | 是否分享 | 目的 | 当前代码/SDK边界 |
| --- | --- | --- | --- | --- |
| 设备或其他 ID | 自动、必需于启用 ML Kit 的构建 | 按 Google 指南为否 | 分析、诊断、防滥用 | ML Kit 的每安装标识；捆绑功能不以唯一识别用户或物理设备为目的 |
| 应用信息和性能 → 诊断 | 自动、必需于启用 ML Kit 的构建 | 按 Google 指南为否 | 分析、诊断 | 设备/应用版本、延迟、API 配置、输入输出尺寸、功能版本、错误代码 |
| 应用活动 → 应用互动 | 自动、必需于启用 ML Kit 的构建 | 按 Google 指南为否 | 分析、诊断 | ML Kit 的初始化、检测、资源释放等事件；最终表单分类需按当时 Play taxonomy 确认 |
| 其他用户生成内容或文件与文档 | 用户可选 | **保守按可能分享处理** | 应用功能 | 只有用户配置并确认 WSS 分析时发送完整棋谱；接收方由用户指定，发行前需决定是否适用“用户发起的操作”例外 |
| 照片和视频 | 仅设备上访问 | 否 | 应用功能 | 棋盘图像送入本机识别；Google 声明 ML Kit 不上传输入图像或识别输出 |
| 本地 SGF/GIB、偏好设置和 token | 仅设备上保存 | 否 | 应用功能 | 棋谱位于应用私有目录，偏好位于 SharedPreferences，token 位于 Keystore 支持的安全存储 |

ML Kit 官方 [Android Data Disclosure](https://developers.google.com/ml-kit/android-data-disclosure)说明其 SDK 收集设备与应用信息、标识、性能指标、API 配置、事件和错误，用于诊断及使用分析，以 HTTPS 传输且不转交第三方。其 [Terms & Privacy](https://developers.google.com/ml-kit/terms)同时说明输入图像与识别结果留在设备上，但 SDK 指标会发往 Google。

## 权限与 SDK 清单

发布构建预期权限：

- `android.permission.CAMERA`
- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`（插件/网络栈合并）

仓库显式移除 `RECORD_AUDIO`、`READ_EXTERNAL_STORAGE` 和 `WRITE_EXTERNAL_STORAGE`。CI 必须对最终 APK/AAB 的合并 Manifest 运行权限 allowlist，不能只检查源码 Manifest。

影响 Data Safety 的主要 SDK：

- `google_mlkit_text_recognition` 0.16.0：MIT 许可的第三方 Flutter 桥，不由 Google 维护。
- Android `com.google.mlkit:text-recognition` 16.0.1：Google 的捆绑 Latin 文本识别 SDK；模型静态进入应用，但 SDK 仍可能联系 Google 并发送上述指标。
- `camera`、`image_picker`、`file_selector`：只在用户操作后访问相机、所选照片或文档；没有广告或行为分析 SDK。
- `flutter_secure_storage`：用于保存 WSS Bearer token，不把 token发送给插件维护者。

## 每个候选版本必须重做

1. 从干净 checkout 构建最终 AAB，并运行 `.github/scripts/verify_android_permissions.sh`。
2. 生成 CycloneDX SBOM，对比 `pubspec.lock`、Gradle runtime graph 和本文件的 SDK 版本。
3. 检查 ML Kit 最新 Data Disclosure、SDK Index 提示及 Google Play 问卷 taxonomy。
4. 用代理或受控测试环境验证图片正文没有发送给 Google，WSS 只在用户确认后连接配置端点。
5. 确认发行主体名称、公开隐私政策 URL、隐私联系机制和删除请求答案一致。
6. 若加入崩溃分析、遥测、默认云服务、账号、推送、广告或模型下载，阻止发布并重新填写全部数据类型。
