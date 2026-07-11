# Visual Benchmark v1

These are strict Flutter render baselines, not the AI-generated visual
references. They protect the approved implementation against accidental visual
drift.

Rendering is fixed to:

- macOS Flutter test rasterizer
- deterministic 463 KiB `LizzieYzy Golden CJK` test subset, derived from
  Noto Sans CJK SC 2.004 under OFL-1.1
- DPR 1.0
- `zh_CN` locale
- text scale 1.0
- reduced motion and disabled tickers
- 393×852 phone or 1024×768 landscape tablet viewport
- explicit light/dark LizzieYZY theme

The subset makes Chinese labels human-readable while keeping font metrics and
raster output deterministic. It is loaded directly by the test harness and is
not declared as a Flutter application asset, so it never enters iOS or Android
packages. `tool/generate_golden_font_subset.py` verifies the upstream source
hash, subsets only repository glyphs, and renames the modified OFL font.

Regenerate intentionally from the repository root:

```sh
flutter test --update-goldens test/golden_test.dart
flutter test test/golden_test.dart
```

Commit a baseline change only after reviewing the old image, new image, and
pixel diff. Do not update goldens merely to make a failing test pass.
