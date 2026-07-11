# Changelog

All notable changes to LizzieYZY Mobile will be documented here. The project
uses semantic versioning after the first stable release.

## [Unreleased]

## [0.1.0] - 2026-07-11

### Added

- Visual Benchmark v1, a token-based Flutter design system, phone
  one-viewport task flows, and expanded tablet review layouts.
- SGF FF[4] collection import and deterministic export, conservative GIB
  import, trusted document types, private on-device persistence, native file
  ingress, and system SGF sharing.
- Camera and gallery capture with bounded image resources, automatic 9/13/19
  board-size and perspective detection, explicit correction, on-device ML Kit
  numbered-diagram evidence, and rule-checked sequence solving.
- User-configured KataGo Analysis JSON over WSS, secure Keychain/Keystore token
  storage, per-send confirmation, app-scoped sessions that can continue after
  leaving the analysis page, cancellation, retry, and deterministic numeric
  review routes through sharing.
- A user-deployed, TLS-only desktop bridge from the App WSS protocol to KataGo
  Analysis JSONL, with Bearer authentication, strict request/compute budgets,
  service/audit manifest binding, immutable private artifact staging, process
  cleanup, and a locked universal Python wheel.
- Manifest-gated single-game performance estimation infrastructure that
  refuses to display a rank interval without a validated production
  calibration artifact.
- Simplified Chinese, Traditional Chinese, English, Japanese, Korean, and 30%
  pseudo-localization resources, accessibility text modes through 3.2x,
  deterministic goldens, visual/brand/privacy/fixture/license guards, and
  Android/iOS release-readiness workflow configuration.
- Pub, CocoaPods, Maven, and Python-bridge CycloneDX SBOM generation and
  validation, including the exact wheel and reviewed license-text hashes.

### Security and privacy

- Delayed camera and photo authorization, private application storage, WSS-only
  service endpoints, secure token storage, bounded parser/image/WebSocket
  inputs, Android permission allowlisting, iOS privacy declarations, and an
  Android Data Safety worksheet.
- Non-blocking native document startup, bounded and cancellable Android/iOS
  reads, typed path-free failures, scene-safe cold-start replay, and preserved
  repeated explicit opens with repository-level content deduplication.
- No default analysis service, mandatory account, advertisement, or upload of
  source board photos with position-analysis requests.

### Known limitations

- Version 0.1.0 does not distribute production HumanSL weights, an authorized
  calibration dataset, or a production calibration artifact, so the product
  does not display a single-game rank interval.
- Recognition coverage is an engineering baseline backed by controlled
  synthetic tests. No licensed independent real-photo dataset report currently
  supports the target point, full-board, or numbered-sequence accuracy claims.
- Real physical-phone interoperability with a user-deployed desktop bridge and
  GPU, 10,000-position desktop parity, physical-device accessibility,
  performance and usability evidence, signed store builds, and store review
  remain release gates.
- Google ML Kit binaries currently block the Apple Silicon iOS 26+ Simulator
  combination because the required `arm64-iphonesimulator` slice is absent.
  The separately verified iOS device `--no-codesign` build does not remove that
  simulator limitation.
