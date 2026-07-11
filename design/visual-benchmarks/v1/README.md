# Visual Benchmark v1

This folder is the versioned visual intent for LizzieYZY Mobile. The PNGs are
design references, never runtime screen slices.

## Direction

- Porcelain `#F7F4ED`, paper `#FFFEFA`, ink `#18201C`.
- Jade `#237B64`, restrained gold `#A97B32`, cinnabar `#C9503B`.
- Dark review surfaces `#111713`, `#19221D`, text `#E9EEE9`.
- Board `#D8B77D`, grid `#59462F`.
- Four-point spacing, 12px cards, 20px review sheets, one elevation level.
- System CJK fonts and tabular numerals; no bundled raster text.

## Handoff contract

1. Use the selected north star for hierarchy, density, material and color.
2. Use `lib/design_system/` tokens for exact implementation values.
3. Build boards, charts, stones and controls with Flutter/Canvas/SVG.
4. Validate implementation with deterministic Flutter goldens, not a raw
   pixel comparison against AI-generated artifacts.
5. Record any accessibility, localization, safe-area or performance deviation
   in a design PR.

## Screens

The ten approved screens cover the happy path and both correction/error paths:
library, camera, physical-board correction, numbered-diagram conflict,
position result, analysis progress, key-move review, single-game performance,
dark variation comparison, and expanded tablet review.

The single-game performance screen intentionally has no history or permanent
rank. The photo-result screen intentionally has no move timeline or strength
estimate.
