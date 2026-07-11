# 发布候选与证据

本仓库的 release-readiness 工作流生成**无签名候选**和可审计证据，不发布商店包，也不把配置完成等同于某次运行已通过。只有公开 GitHub Actions 运行、对应 commit 和下载后的摘要能证明某个候选经过这些门禁。

## 触发与版本

- tag 触发必须严格使用 `v<pubspec version>`，包含 build metadata。例如 `version: 0.1.0+1` 只能由 `v0.1.0+1` 触发。
- `.github/scripts/verify_release_tag.py` 在任何构建 job 之前执行；缺 tag、去掉 `+1` 或指向不同版本都会失败。
- `workflow_dispatch` 是不发布的人工 readiness 运行，没有 tag，因此合理跳过 tag 等值门禁；它不会创建或移动 tag。

## 同一候选

Android 和 iOS job 各自构建一次候选，立即运行最终包许可、权限或隐私门禁，记录候选摘要并使用 GitHub `actions/attest` 的 build-provenance 模式签名。后续 supply-chain job 只下载这些候选，不重新构建二进制；它会重新计算摘要并验证两份签名 provenance。

Android 候选同时保存：

- R8 `mapping.txt`；
- AGP `native-debug-symbols.zip`（`SYMBOL_TABLE`）；
- 不启用 Dart obfuscation、仅以 `--split-debug-info` 产生的 arm、arm64、x64 Flutter AOT symbols；开源候选保持可审计。

iOS 候选同时保存 Flutter split-debug-info 和 `build/ios/Release-iphoneos` 下全部 dSYM。`tool/release_symbols.py` 递归枚举每个 dSYM，将其 DWARF UUID 与最终 `Runner.app` 内对应 Runner/Framework Mach-O UUID 精确比较，再生成确定性 symbol archive 和逐文件 SHA-256 manifest。缺少 Runner/App dSYM、出现孤立 dSYM、UUID 不同、符号 archive 下载后变化都会失败。

## Gradle wrapper 信任边界

真正执行的是仓库中的 `android/gradlew`、`gradle-wrapper.jar` 和 `gradle-wrapper.properties`，不是仅记录 distribution URL。`android/gradle/wrapper/gradle-wrapper-integrity.json` 锁定：

- Unix/Windows wrapper 脚本；
- wrapper JAR；
- wrapper properties；
- 文件大小、SHA-256 和 Unix 可执行位；
- Gradle distribution URL 与官方发布摘要。

`.github/scripts/verify_gradle_integrity.py` 同时验证上述 manifest、distribution 和 dependency verification metadata。升级 Gradle 时必须由维护者重新生成官方 wrapper、独立核对 distribution 摘要，审查脚本/JAR diff，然后显式更新 integrity manifest；不得用 CI 自动接受未知新摘要。

## 确定性证据包

最终 `LizzieYZY-Mobile-release-evidence.zip` 使用固定条目排序、固定 ZIP 时间戳、固定权限表达和不依赖宿主绝对路径的逻辑路径生成。同一组输入会得到相同字节。包内包括：

- 两个平台的原始无签名候选、候选摘要和 GitHub build-provenance Sigstore bundle；
- Android/iOS symbol archive 与逐文件 manifest；
- 四生态 CycloneDX SBOM、完整第三方许可文本和候选摘要；
- Gradle wrapper/verification lock、Podfile.lock、Ruby/CocoaPods Gemfile.lock、Python requirements lock；
- 自定义 release-integrity predicate；
- 覆盖包内全部内容（不自包含）的 `checksums.sha256`。

`release-integrity` predicate 只声明“候选摘要与证据完整性绑定”，并显式设置 `buildProvenance: false`。它的类型是：

```text
https://github.com/wimi321/lizzieyzy-mobile/attestations/release-integrity/v1
```

它不是 SLSA build provenance，不能替代两个构建 job 产生的 GitHub provenance。工作流最后以该自定义 predicate 对**最终证据 ZIP**签名，并再次用 GitHub CLI 指定 predicate type 验证。

```bash
gh attestation verify LizzieYZY-Mobile-release-evidence.zip \
  --repo wimi321/lizzieyzy-mobile \
  --predicate-type \
  https://github.com/wimi321/lizzieyzy-mobile/attestations/release-integrity/v1
```

解压后应从包内逻辑根目录按 `checksums.sha256` 复算全部条目。签名、证据和符号不使无签名 APK/Runner.app 成为商店候选。正式发布仍需受控签名密钥、商店证书/账号、真机验证、隐私表单和目标市场合规证据。
