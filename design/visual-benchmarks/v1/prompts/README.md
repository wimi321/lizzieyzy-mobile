# Imagegen prompt set

Mode: built-in `imagegen`, one call per distinct screen.

## Shared prompt contract

```text
Use case: ui-mockup
Asset type: full-screen shippable Flutter mobile UI benchmark
Style: modern Eastern minimalism; realistic production interface; no device frame
Palette: porcelain, paper, ink, jade, restrained gold, cinnabar; warm Go board only
Typography: exact Simplified Chinese, system sans, tabular numerals, body >= 14pt
Constraints: touch targets >= 44pt; WCAG-friendly contrast; one elevation level
Avoid: glass, neon, heavy gradients/shadows, nested cards, desktop UI, watermark
```

## Screen prompts

- `north-star-01`: move 87 review, dominant 19x19 board, A/B/C, exact strip
  `实战 Q16 / 最佳 R14 / -5.2目 / -18.4pp`, four review tabs.
- `screen-01`: `棋谱` home, photo scan CTA, two recent records, SGF/Fox/OGS.
- `screen-02`: physical-board camera, four aligned corners, level, shutter.
- `screen-03`: six numbered uncertain intersections, original crop, black/white/
  empty/unknown correction, disabled completion.
- `screen-04`: printed numbered diagram, ambiguous move 87, repeated-point or
  capture conflict, pass repair, save-as-partial fallback.
- `screen-05`: current-position result, black/white counts, explicit next player,
  Chinese rules and 7.5 komi; never claim a recovered timeline.
- `screen-06`: standard analysis at `142/236`, 1000 visits per turn, local
  backend, pause/cancel/background controls.
- `screen-08`: only this game's `3级–1级` 80% interval, 86 valid decisions,
  phase metrics and fixed non-official-rank disclaimer. A targeted edit removed
  decorative ink-wash artwork while preserving the UI.
- `screen-09`: graphite variation comparison, actual Q16 vs candidate R14,
  numbered 1–8 PV and `57.8% / +3.1目 / 12,840访问`.
- `screen-10`: 1024x768 three-pane tablet review with a full-width timeline.

Every generated source was inspected. Screen-specific prompts add only the
content above and repeat the shared constraints. Full prompt provenance and
hashes are recorded in `../manifest.json`.
