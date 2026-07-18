# WBS 2.2 — Color and opacity tokens implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-2.2-01` |
| Test | `TEST-WBS-2.2-01` |

## Canonical inputs

- `docs/design/MemoX Design System_v4/tokens/colors.css` (single source of
  every colour value; light in the `:root`/light block, dark in
  `[data-theme='dark']`, theme-independent selectable palette in plain
  `:root`) and `tokens/opacity.css`.
- `docs/design/token-manifest.json` — 75 tokens owned by this item
  (64 themed colors ×2 themes, 6 palette, 5 opacity), symbols fixed by the
  manifest rule.
- Guard scope `flutter_app_source` excludes `lib/core/theme/**`, the only
  layer allowed to hold color literals.

## Scope

Create:

- `tool/design/color_tokens.mjs` — one-shot generator emitting the Dart
  token files from the CSS (avoids 75 hand-transcription errors);
  regenerate with `--write` whenever kit values change.
- `lib/core/theme/tokens/app_colors.dart` — generated `AppColorTokens`
  (64 semantic roles incl. state layers, snackbar grounds and the viz-1..6
  chart namespace with aliases resolved per theme) with `AppColors.light`
  / `AppColors.dark` const instances, plus the 6 theme-independent
  `palette*` constants; every token exposed via `byToken` maps keyed by
  frozen CSS name.
- `lib/core/theme/tokens/app_opacities.dart` — generated 5-value opacity
  scale with `byToken`.
- `test/core/theme/token_css_parity_test.dart` — re-parses the CSS at gate
  time (selector-aware, var()-alias resolving) and compares **every** value
  and the full key sets in both themes; any kit value change or omission
  fails the gate until regenerated.
- `test/core/theme/app_colors_contrast_test.dart` — executable contrast
  evidence (KIT-08): text/secondary/tertiary on canvas+surface ≥ 4.5:1,
  all on-color pairs ≥ 4.5:1, snackbar text ≥ 4.5:1 and accents ≥ 3:1 on
  their opaque grounds, focus ring ≥ 3:1 — in both themes.

Out of scope: theme extensions/accessors (2.6), ThemeData assembly (2.7),
high-contrast override values (2.9 — `[data-hc]` file), typography/spacing
families (2.3/2.4).

## Acceptance and test procedure

`AC-WBS-2.2-01` is true only when:

1. All 75 manifest tokens owned by 2.2 exist in Dart with the manifest's
   exact symbols and values byte-derived from the kit CSS.
2. The CSS↔Dart parity test covers every themed token in both themes, the
   palette and the opacity scale, and fails on any drift.
3. Contrast evidence passes for the pairs the kit claims (normal-text AA
   and UI 3:1) in light and dark.
4. Full canonical gate passes.

`TEST-WBS-2.2-01`:

- `token_css_parity_test.dart` and `app_colors_contrast_test.dart` (11
  tests) — both run inside `flutter test` at every gate.
- Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Kit value change: rerun `--write`, review the diff, parity test goes
  green again; never hand-edit the generated files.
- Success: record register evidence, mark `2.2` Done, then author `2.3`
  (typography) next.
