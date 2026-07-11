# Visual Benchmark v1

These are strict Flutter render baselines, not the AI-generated visual
references. They protect the approved implementation against accidental visual
drift.

Rendering is fixed to:

- macOS Flutter test rasterizer and Flutter's deterministic Ahem test font
- DPR 1.0
- `zh_CN` locale
- text scale 1.0
- reduced motion and disabled tickers
- 393×852 phone or 1024×768 landscape tablet viewport
- explicit light/dark LizzieYZY theme

The Ahem font intentionally renders text as geometric blocks. This keeps text
metrics deterministic and makes layout, spacing, clipping, color, board, and
component regressions strict. Human-readable visual review belongs to the
separate generated design references and real-device screenshots.

Regenerate intentionally from the repository root:

```sh
flutter test --update-goldens test/golden_test.dart
flutter test test/golden_test.dart
```

Commit a baseline change only after reviewing the old image, new image, and
pixel diff. Do not update goldens merely to make a failing test pass.
