# WBS 2.5 — Motion/icon tokens implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.1` — Done |
| Decision gates | DG-02 |
| Acceptance | `AC-WBS-2.5-01` |
| Test | `TEST-WBS-2.5-01` |

## Canonical inputs

- Kit `tokens/motion.css` (7 durations incl. the reduced-motion primitive,
  3 cubic-bezier easings) and `tokens/icon-size.css` (4 glyph sizes) — the
  14 manifest tokens owned by this item.
- Kit icon usage: Material Symbols **Rounded** at default axes — no
  `font-variation-settings` override anywhere in the kit (verified by scan);
  sizes 20/24 intentionally reuse the type scale.

## Scope

Create:

- `lib/core/theme/tokens/app_motion.dart` — `Duration` constants for the
  transition scale, feedback flash and shimmer pulse, the near-zero
  `durationNone` reduced-motion primitive (contract: the theme layer swaps
  scale durations to it when `MediaQuery.disableAnimations` is true —
  KIT-04-05/KIT-38-06), and the three `Cubic` easings
  (standard/decelerate/accelerate); `durationMsByToken` + `easingByToken`.
- `lib/core/theme/tokens/app_icon_sizes.dart` — 4 glyph sizes + the
  Material Symbols mapping contract (`iconFontFamily = 'Material Symbols
  Rounded'`, default FILL 0 / wght 400 / GRAD 0, optical size tracks glyph
  size). The Flutter glyph adapter is owned by WBS 3.1; its approved
  implementation vehicle is the `material_symbols_icons` pub package, to be
  version-evidenced in the 3.1 packet.
- `test/core/theme/motion_icon_css_parity_test.dart` — durations (ms) and
  easing control points re-parsed from CSS and compared exactly;
  Duration-constant agreement (incl. `durationNone > 0` so completion
  callbacks fire); icon sizes; Rounded-style contract.

Out of scope: animated component behavior (3.x), reduced-motion switch
implementation (2.6/2.7), the icon glyph adapter itself (3.1).

## Acceptance and test procedure

`AC-WBS-2.5-01` is true only when:

1. All 14 manifest tokens exist with exact kit values.
2. The reduced-motion primitive is non-zero and documented as the
   disableAnimations swap target.
3. The Material Symbols contract (family, style, default axes, type-scale
   reuse rule) is written in the token layer for 3.1 to consume.
4. Full canonical gate passes.

`TEST-WBS-2.5-01`: `motion_icon_css_parity_test.dart` (5 tests) inside
every `flutter test` gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `2.5` Done. All 207 manifest
  tokens now have Dart implementations; next is `2.6` (theme
  extensions/accessors).
