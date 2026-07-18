# WBS 2.9 — High-contrast readiness implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.7`, `0.6` — Done |
| Decision gates | DG-02, DG-05 (v1 scope exclusions) |
| Acceptance | `AC-WBS-2.9-01` |
| Test | `TEST-WBS-2.9-01` |

## Decision — explicitly deferred, readiness delivered

The WBS row allows "implemented and tested **or explicitly deferred with no
false support claim**". The accepted v1 scope (WBS 0.6; design `SCOPE.md`:
"high-contrast tokens exist but release evidence is tracked separately")
excludes shipping a high-contrast mode. This packet therefore delivers the
**readiness half** and records the **explicit deferral**:

- The app does **not** branch on `MediaQuery.highContrast` and ships no
  high-contrast setting — no false support claim anywhere.
- The token layer is complete and merge-ready, so a future scope decision
  wires the profile without re-deriving values.

## Canonical inputs

- Kit `tokens/high-contrast.css` — additive opt-in profile
  (KIT-08-06/KIT-39-05): six role overrides per base theme (hairline
  borders, secondary/tertiary text, focus ring).
- Token manifest: the 12 declarations override names owned by
  `app_colors.dart`; no new token names.

## Scope

Create:

- `lib/core/theme/tokens/app_high_contrast_overrides.dart` —
  `HighContrastOverrides` (six roles, `byToken`), kit values for light and
  dark bases, and `applyHighContrast(base, overrides)` merging via the
  generated `AppColorTokens.copyWith` (additive: every other role
  untouched). The release-status deferral is documented at the top of the
  file.
- `test/core/theme/high_contrast_css_parity_test.dart` — exact parity with
  both CSS selector blocks; merge additivity; evidence the profile
  actually raises contrast over both bases (secondary text > 7:1).

Modify:

- `tool/design/color_tokens.mjs` — `AppColorTokens` gains a generated
  field-wise `copyWith`; `app_colors.dart` regenerated.

Out of scope: runtime wiring (`MediaQuery.highContrast` branch, settings
toggle, high-contrast ThemeData variants) — blocked on a future
product-scope decision; KIT-39-05 release evidence stays tracked
separately per `SCOPE.md`.

## Acceptance and test procedure

`AC-WBS-2.9-01` is true only when:

1. Both override sets match the kit CSS exactly and merge additively.
2. The measured contrast of overridden roles is strictly higher than the
   base (and ≥ 7:1 for secondary text on the canvas).
3. No production code path claims high-contrast support.
4. Full canonical gate passes.

`TEST-WBS-2.9-01`: `high_contrast_css_parity_test.dart` (4 tests) in every
gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `2.9` Done, then author `2.10`
  (foundation contract tests — the wave-2 gate) next.
