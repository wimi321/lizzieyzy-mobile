# Brand benchmark v1

The launcher icon uses the same porcelain, jade, ink, ivory, and restrained
gold language as Visual Benchmark v1. Three imagegen candidates were scored for
Go recognition, small-size legibility, distinctiveness, platform fit, and
accessibility. Candidate 03 scored 95 and is the only selected source.

The selected 1024×1024 source has no alpha channel and no pre-rounded outer
mask. `tool/generate_app_icons.sh` mechanically produces every legacy iOS and
Android raster size. Android 8+ additionally uses a code-native adaptive icon;
Android 13+ receives a monochrome themed icon. The generated candidates are
design provenance, not runtime screen assets.

## Prompt lineage

1. Seal grid: centered jade seal/focus form, five-by-five grid, black and white
   stones, porcelain background, one gold analysis accent, no text or effects.
2. Minimal grid: rounded three-by-three jade grid with two diagonal stones and
   a small gold analysis point, optimized for negative space.
3. Selected bold analysis: a heavy jade rounded-square seal, thick porcelain
   grid cuts, black and ivory stones, and a restrained gold comparison notch,
   explicitly optimized to remain identifiable at 24–32px.

All candidates were generated with the built-in image generator on 2026-07-11.
The exact files and SHA-256 values are frozen in `manifest.json`.
