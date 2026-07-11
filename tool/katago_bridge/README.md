# LizzieYZY KataGo Bridge

这是一个最小化、可审计的参考实现：把 LizzieYZY Mobile 的 WSS 请求逐行转发给桌面端 KataGo Analysis JSONL，并把 KataGo 的 JSONL 结果逐行送回手机。它不提供明文 WS 模式，不代理任意命令，也不内置引擎或模型。

## 安全边界

- 仅支持 Python 3.12；唯一运行时依赖固定为 `websockets 16.0` 的通用 wheel，并校验 SHA-256。
- 启动必须同时提供 TLS 证书和私钥；私钥在 POSIX 系统上不得对 group/other 可读。手机必须信任该证书或签发它的 CA，没有跳过证书验证的开关。
- Bearer token 只能来自环境变量，或当前用户拥有且权限严格为 `0600` 的普通文件。鉴权比较采用固定长度 SHA-256 digest 和 `hmac.compare_digest`。
- 默认只允许一个活跃连接；每个连接启动独立 KataGo 子进程，连接关闭、超限、超时和服务器停机都会终止并回收整个进程组。
- 对 WebSocket message/frame、JSONL 行、每消息行数、JSON 深度/结构量、每连接请求数、进程启动/生存/清理时间设置硬上限。压缩关闭，浏览器 `Origin` 请求不接受。
- 已鉴权客户端仍只能提交 App 当前协议的严格对象：9/13/19 路、完整连续 `analyzeTurns`、最多 999 手、20,000 visits、128 PV、受支持规则/komi/布尔字段和 manifest 声明的 HumanSL profile；未知字段、错误类型、超额计算以及不属于本连接的 `terminateId` 均 fail-closed。
- 服务只记录不含用户数据的启动信息。Authorization、请求内容、棋谱、KataGo stdout/stderr 均不写日志；Bearer 环境变量及常见 secret 环境变量不会传给 KataGo。
- 启动时检查 KataGo analysis config，要求 `logAllRequests`、`logAllResponses`、`logErrorsAndWarnings`、`logSearchInfo` 四项均显式且唯一地设为 `false`，避免引擎自己的文件日志落下棋谱或分析内容。
- 启动必须同时加载 service/audit manifest，逐项核对 service digest、endpoint、perspective 以及 engine/config/normal/HumanSL 的 SHA-256 和大小。通过后才把同一打开文件描述符的内容复制进 `0700` 私有临时目录；引擎副本为 `0500`，配置和模型为 `0400`，KataGo 始终使用内容寻址副本，停机后删除 staging。
- 普通分析对象和官方 `terminate` action 会在验证后按原 JSON 行透传。其他 action 直接拒绝。

此桥只适合用户控制的桌面或可信局域网主机。仍建议用主机防火墙只允许受信任 LAN/VPN 地址访问，不要把端口直接暴露到公网。

## 可复现安装

```sh
python3.12 -m venv tool/katago_bridge/.venv
tool/katago_bridge/.venv/bin/python -m pip install --require-hashes \
  -r tool/katago_bridge/requirements.lock
```

Windows 使用 `tool\katago_bridge\.venv\Scripts\python.exe`。依赖的 BSD-3-Clause 许可证原文位于 `tool/katago_bridge/LICENSES/websockets-BSD-3-Clause.txt`。

## TLS 与 token

证书的 SAN 必须包含手机实际连接的 DNS 名称或 IP；自建 CA 时必须先安全地安装并信任 CA。以下只展示 token 文件的安全创建方式，不生成或处理 TLS 私钥：

```sh
umask 077
python3.12 -c 'import secrets; print(secrets.token_urlsafe(48))' > bridge.token
chmod 600 bridge.token
chmod 600 server.key
```

也可只使用环境变量：

```sh
export LIZZIEYZY_BRIDGE_TOKEN="$(python3.12 -c 'import secrets; print(secrets.token_urlsafe(48))')"
```

若同时存在所选环境变量和 `--token-file`，桥会拒绝启动。Windows 无法可靠验证 POSIX `0600`，因此仅允许环境变量方式。

## 双模型启动

标准复盘可以只传 normal model；要让 App 获得 `humanPolicy` 并进入可信单局棋力链，必须同时提供 normal model 和独立 HumanSL model：

所用 `analysis.cfg` 至少必须包含以下隐私设置；其余 GPU、线程和 `reportAnalysisWinratesAs` 参数仍由用户按硬件配置：

```ini
reportAnalysisWinratesAs = SIDETOMOVE
logAllRequests = false
logAllResponses = false
logErrorsAndWarnings = false
logSearchInfo = false
```

```sh
PYTHONPATH=tool tool/katago_bridge/.venv/bin/python -m katago_bridge \
  --host 0.0.0.0 \
  --port 8443 \
  --route /v1 \
  --cert-file /secure/server.crt \
  --key-file /secure/server.key \
  --token-file /secure/bridge.token \
  --engine /opt/katago/katago \
  --katago-config /opt/katago/analysis.cfg \
  --model /opt/katago/normal-model.bin.gz \
  --human-model /opt/katago/human-model.bin.gz \
  --service-manifest /secure/service-manifest.json \
  --audit-manifest /secure/bridge-artifact-manifest.json
```

桥不会接受 shell 字符串或任意额外参数，而是固定构造：

```text
katago analysis -config <cfg> -model <normal> -human-model <HumanSL>
```

不能把 HumanSL 文件只放到主 `-model` 位置来替代双模型启动。那样无法为 normal model 的分析结果提供独立 `humanPolicy`，App 会按 fail-closed 规则拒绝显示棋力区间。

默认进程生存上限为 50 分钟，与 App 的 45 分钟分析期限留有清理余量。所有资源上限都可通过 `--help` 查看并向下调整。

## 生成导入清单

生成器输出两个严格分离的文件：

- `service-manifest.json`：只给 App 导入；不含 token、文件路径或未知顶层字段。
- `bridge-artifact-manifest.json`：留在桌面端审计并在每次启动时强制加载；记录 engine、analysis config、normal model、HumanSL model 的独立 SHA-256/大小，以及 service manifest 的 SHA-256。

```sh
PYTHONPATH=tool tool/katago_bridge/.venv/bin/python -m katago_bridge.manifest \
  --endpoint wss://gpu.home.example:8443/v1 \
  --engine /opt/katago/katago \
  --katago-config /opt/katago/analysis.cfg \
  --model /opt/katago/normal-model.bin.gz \
  --human-model /opt/katago/human-model.bin.gz \
  --model-id kata-normal-human \
  --display-name "KataGo Normal + HumanSL" \
  --engine-version 1.16.5 \
  --model-version b18c384 \
  --model-license CC-BY-4.0 \
  --model-source https://example.org/model-card \
  --human-style-rank 3k \
  --human-style-rank 1d \
  --output service-manifest.json \
  --audit-output bridge-artifact-manifest.json
```

只要声明任一 `--human-style-rank`，`--human-model` 就是必需项。App-facing `model.sha256` 始终是 normal model 的 hash，`model.humanModelSha256` 始终是独立 HumanSL 文件的 hash；两者不会互相代用。Bearer token 必须通过 App 的独立安全输入/存储流程配置，不能写进任何 manifest 或 endpoint。

生成器从同一个 `--katago-config` 唯一派生 `reportAnalysisWinratesAs`。可额外传 `--report-analysis-winrates-as` 做断言，但只要不完全一致就拒绝生成；缺失或重复配置同样拒绝。生成器拒绝让两个输出互相覆盖，也拒绝用输出文件覆盖 engine、config 或任一 model。

## 验证

```sh
python3.12 -m py_compile tool/katago_bridge/*.py tool/katago_bridge/tests/*.py
PYTHONPATH=tool python3.12 -m unittest discover -s tool/katago_bridge/tests -v
ruff check tool/katago_bridge
```

测试使用独立 fake KataGo 子进程，覆盖鉴权、请求 schema/计算预算、普通请求与 `terminate` 原样透传、进程超时/取消/清理、双模型完整参数、四份 artifact 替换拒绝、perspective 绑定、内容寻址 staging/权限/清理和无 secret manifest。
