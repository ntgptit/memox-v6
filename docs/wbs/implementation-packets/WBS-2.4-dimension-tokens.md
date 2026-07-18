# WBS 2.4 — Spacing/size/radius/stroke/elevation tokens implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.1` — Done |
| Decision gates | DG-02 |
| Acceptance | `AC-WBS-2.4-01` |
| Test | `TEST-WBS-2.4-01` |

## Canonical inputs

- Kit `tokens/{spacing,size,radius,stroke,elevation,component}.css` — the 91
  manifest tokens owned by this item (spacing 31, size 11, radius 13,
  stroke 5, elevation 6 themed, component 25).
- `docs/design/token-manifest.json` symbols.
- 4px rhythm rule; safe-area tokens are `max(env(...), <min>)` expressions
  whose kit-rendered minimums Flutter owns (platform insets win at runtime
  via `SafeArea`/`MediaQuery`).

## Scope

Create (all under `lib/core/theme/tokens/`, the guard-approved literal
layer):

- `app_spacing.dart` — 14-step 4px scale, gutters, content-width caps,
  safe-area minimums, app-bar/bottom-nav/FAB/touch metrics and the
  `layout-*` aliases (values bound to their originals).
- `app_sizes.dart` — 11-step element size scale.
- `app_radii.dart` — 6-step radius scale + 7 role aliases.
- `app_strokes.dart` — 5 border widths (theme-independent).
- `app_component_dimensions.dart` — 25 `--memox-comp-*` control dimensions.
- `app_elevations.dart` — themed `BoxShadow` lists for
  sm/card/lg/fab/nav/ring-focus: layered violet-grey casts in light,
  hairline ring + deep ambient in dark; the focus ring composes
  stroke-focus width with the theme's `focus-ring` color token.
- `test/core/theme/dimension_css_parity_test.dart` — numeric families are
  re-parsed from CSS (alias-resolving) and compared as full maps; safe-area
  expressions and every elevation string are pinned as drift tripwires; the
  focus-ring shadow color is asserted equal to `AppColors.*.focusRing`.

Out of scope: responsive class boundaries (2.8), theme extensions (2.6),
motion/icon families (2.5), high-contrast values (2.9).

## Acceptance and test procedure

`AC-WBS-2.4-01` is true only when:

1. All 91 manifest tokens exist with exact kit values and manifest symbols;
   no raw literal above the token layer.
2. Parity tests compare complete key sets (a missing or extra token fails).
3. Elevation/safe-area kit changes trip the pinned-string tests until the
   Dart layer is updated in the same change.
4. Full canonical gate passes.

`TEST-WBS-2.4-01`: `dimension_css_parity_test.dart` (8 tests) inside every
`flutter test` gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `2.4` Done, then author `2.5`
  (motion/icon) next.
