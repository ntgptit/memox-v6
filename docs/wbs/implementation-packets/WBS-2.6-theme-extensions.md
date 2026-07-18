# WBS 2.6 — Theme extensions/accessors implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.2`–`2.5` — Done |
| Decision gates | DG-02 |
| Acceptance | `AC-WBS-2.6-01` |
| Test | `TEST-WBS-2.6-01` |

## Canonical inputs

- Token layer `lib/core/theme/tokens/**` (all 207 tokens, WBS 2.2–2.5).
- Kit `guidelines/type-scale.html` — the semantic role table
  (Display 3xl/800, Headline 2xl/800, Title xl/700, Subtitle lg/700,
  Body-large md/600, Body base/400, Caption sm, Overline xs/caps).
- Guard rules: `no_theme_token_imports` (features consume via accessors;
  shared `Mx*` widgets may import tokens), `no_direct_text_theme`
  (semantic roles, not Material textTheme), `theme_file_no_riverpod`,
  `no_theme_export_wrappers`.

## Scope

Create (`lib/core/theme/extensions/`):

- `app_colors_extension.dart` / `app_elevations_extension.dart` —
  `ThemeExtension`s carrying the active theme's `AppColorTokens` /
  `AppElevationTokens` with const light/dark instances. `lerp` is a
  documented discrete midpoint switch: the perceived theme crossfade is
  owned by the Material color-scheme lerp in ThemeData (2.7).
- `app_text_styles.dart` — semantic text roles exactly as the kit table
  specifies (family/size/weight; overline adds caps tracking via the em→px
  converter). Roles carry only what the kit specifies: color comes from
  `context.colors`, line heights from component specs. `MxText` (3.1) is
  the feature-facing API.
- `app_theme_context.dart` — `context.colors`, `context.elevations`,
  `context.textStyles` accessors; responsive `context.spacing`/`layout`
  arrive with 2.8.
- `test/core/theme/theme_extensions_test.dart` — light/dark resolution
  through real `Theme` lookups, role-table parity against typography
  tokens, discrete-lerp behavior.

Out of scope: ThemeData assembly and component themes (2.7), responsive
accessors (2.8), `MxText` (3.1), high-contrast (2.9). No Riverpod anywhere
in `lib/core/theme/**`.

## Acceptance and test procedure

`AC-WBS-2.6-01` is true only when:

1. Colors/elevations/text contracts are reachable from widgets exclusively
   via `BuildContext` accessors backed by `ThemeExtension`s.
2. Text roles match the kit type-scale table exactly and nothing more.
3. The theme layer stays token-only (no Riverpod, no export wrappers).
4. Full canonical gate passes.

`TEST-WBS-2.6-01`: `theme_extensions_test.dart` (5 tests) in every
`flutter test` gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `2.6` Done, then author `2.7`
  (theme assembly) next.
