# 隐私政策 / Privacy Policy

生效日期：2026-07-11

LizzieYZY Mobile 由 `wimi321` 维护，是一款本地优先的开源围棋复盘应用。本政策描述当前仓库构建的 iOS 与 Android 应用如何访问、保存和传输数据。商店中的发行主体如果不是 `wimi321`，必须在发布前同步更新本文件、商店隐私标签和应用内披露。

## 核心结论

- 应用没有广告、账号、跨应用跟踪或由项目维护者运营的分析后台。
- 棋谱、棋盘照片和识别结果默认在设备上处理。导入棋谱会保存在应用私有目录；访问令牌保存在 Keychain/Keystore。
- ML Kit 的图像输入和识别结果由 Google 声明为完全在设备上处理，不发送给 Google；但 ML Kit SDK 会向 Google 发送设备/应用信息、安装标识、性能、API 配置、事件与错误等诊断和使用指标。
- 只有用户配置一个 `wss://` KataGo 服务并确认远端分析时，应用才会把完整棋谱和分析参数发送到该服务。该服务不是本项目运营的服务，其运营者、日志和保留规则由用户选择并承担。

## 应用访问和保存在设备上的数据

| 数据 | 用途 | 保存与删除 |
| --- | --- | --- |
| 相机画面和用户选择的照片 | 识别实体棋盘或编号棋谱 | 处理副本和拍照临时文件仅用于当前任务，并尽力及时删除；相册中的原文件不由应用删除 |
| SGF/GIB 棋谱和识别结果 | 导入、校对、复盘、再次打开 | 以有版本和完整性校验的格式保存在应用私有目录，直到用户清除应用数据或卸载应用 |
| 主题、语言、分析档位、服务清单 | 恢复应用设置 | 保存在平台偏好设置中，直到清除应用数据或卸载应用 |
| KataGo Bearer token | 连接用户指定的分析服务 | 只保存在 iOS Keychain 或 Android Keystore 支持的加密存储中；移除服务配置时删除 |
| 临时分享 SGF | 调起系统分享面板 | 应用在启动、恢复前台和下一次分享前，以有界、尽力而为的方式清理超过 24 小时且带应用所有权标记的临时导出；接收应用取得的副本受接收方政策约束 |

应用不会主动读取整套照片图库或任意存储目录。相册、文件导入和系统分享均由用户明确发起，并通过平台选择器或文档权限完成。

iOS Keychain 项可能在卸载后继续存在。为避免重新安装的应用静默继承旧凭据，iOS 版本在普通 UserDefaults 中保存一个不含秘密的安装标记；新安装首次启动发现标记缺失时，会先删除可能残留的 KataGo Bearer token，再写入当前安装标记。若清理或标记写入失败，设置初始化会失败并在下次启动重试，不会放行残留 token。此流程只在 iOS 启用，不改变 Android 的 Keystore 存储行为。升级到首次包含此保护的版本时也会执行一次凭据清理，用户需要重新填写 token。

SGF 只接受严格 UTF-8。GIB 可在设备上确定性识别 UTF-8、CP949、GB18030/GBK 或 Big5；检测使用有界字节流、严格解码、原字节往返校验和棋谱结构校验，不调用系统或云端编码探测服务。检测到的旧版 GIB 编码会在导入结果中显示，无法明确判断时拒绝导入。

## 设备外传输

### Google ML Kit

当前编号识别使用 `google_mlkit_text_recognition` Flutter 插件调用 Google 原生 ML Kit Text Recognition SDK。插件本身不是 Google 产品；它通过平台通道调用 Google SDK。

Google 的 [ML Kit Terms & Privacy](https://developers.google.com/ml-kit/terms) 声明：输入图像、文本和识别输出在设备上处理，不发送给 Google；SDK 可能联系 Google 获取修复、模型或硬件兼容信息，并发送性能和使用指标。Google 的 [Android Data Disclosure 指南](https://developers.google.com/ml-kit/android-data-disclosure)列出的指标包括设备与应用信息、安装标识、性能、API 配置、输入输出尺寸、功能版本、事件类型和错误代码。这些指标由 Google 依据其条款和隐私政策处理。

### 用户配置的 KataGo WSS 服务

远端分析不是默认云服务。启用后，应用会向用户导入并保存的 `wss://` 端点发送完整棋谱、规则和有界分析参数；如果配置了 Bearer token，该 token 会随连接发送。服务通常还会看到网络连接所必需的 IP 地址。应用只接受加密的 WSS 端点，但不能控制服务端是否记录、保留或再处理数据。

在发送前，应用默认要求用户确认。用户应只连接自己信任且有明确隐私政策的服务；敏感棋谱不应发送到未知端点。

### 系统分享

用户可把 SGF 明确分享给其选择的应用或服务。系统分享面板和接收方对数据的处理受相应平台和接收方政策约束。

应用把临时 SGF 写入仅由导出服务管理的私有 `lizzieyzy-share` 目录。Android 上 `share_plus` 还会在同一应用沙箱的私有 `share_plus` 缓存目录生成用于 `FileProvider` 的副本；iOS 对已有文件路径不生成该副本。应用清理前一目录内超过 24 小时的 SGF；对插件共用目录则只清理文件名带 LizzieYZY 所有权标记且超过 24 小时的 SGF。单次扫描和删除均有上限，失败不会阻止启动、恢复或后续分享。应用不递归扫描、不删除其他临时文件，也无法删除接收方保存的副本。

## 权限

- 相机：仅在用户进入拍照识谱并授权后使用；不录音。
- 照片：仅访问用户通过系统选择器选中的图片。
- 文件：仅访问用户选择或通过系统“打开方式/分享”交给应用的 SGF/GIB。
- 网络：用于用户配置的 WSS 分析，以及 ML Kit SDK 按 Google 文档进行的维护和指标传输。

应用不请求位置、联系人、麦克风、短信、通话记录或广告标识权限。

## 保留、删除与安全

应用没有项目方账号或云端棋谱库，因此项目维护者通常没有可供查询或删除的用户内容。用户可以移除分析服务配置、通过系统清除应用数据，或卸载应用来删除应用私有目录中的本地数据。由于 iOS Keychain 的平台保留规则可能与应用容器不同，应用不能承诺卸载动作本身立即删除 token；重新安装后的首次启动会按上文流程在使用任何旧 token 前将其清除。已发送到用户选择的远端服务或分享接收方的数据，必须向该运营者请求删除。

本地导入实施字节、字符、树深、节点和属性上限；图片处理实施帧数、编码大小、尺寸和像素预算；远端分析只允许 WSS。安全边界和私密漏洞报告方式见 [SECURITY.md](SECURITY.md)。

## 儿童、变更与联系

本应用不以儿童为目标用户，也不会有意收集儿童账户资料。政策随实际数据流、SDK 或商店要求变化时会在仓库中更新生效日期。隐私或安全问题请优先使用 GitHub 仓库的私密漏洞报告入口；不要在公开 issue 中附上真实棋谱、照片、令牌、IP 或文件路径。

## English summary

LizzieYZY Mobile is local-first and has no ads, accounts, cross-app tracking, or project-operated analytics backend. Imported records are stored in the app-private directory, settings are stored locally, and service tokens use Keychain/Keystore. Because iOS Keychain items can survive uninstall, a non-secret install marker causes a newly installed copy to delete any orphaned service token before accepting the installation; Android behavior is unchanged. App-owned temporary SGF exports and marked Android `share_plus` copies older than 24 hours are cleaned on startup, foreground resume, and before a new share using bounded, best-effort work; unrelated cache files are not eligible. ML Kit processes image inputs and recognition outputs on-device, but Google documents that its SDK sends device/app information and diagnostic and usage metrics to Google. A complete game record is sent only when the user configures and approves a third-party `wss://` KataGo service. The selected service and share recipients have their own retention and privacy practices.
