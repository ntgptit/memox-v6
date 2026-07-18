# WBS 3.3 — `MxTextField` and form foundation implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — children A–C complete |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `3.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.3-01` |
| Test | `TEST-WBS-3.3-01` |

## Canonical inputs

- Kit `components/core/MxTextField.prompt.md` (frozen) + `.field` /
  `.field-group` CSS: bare by default (visible box belongs to the
  container), labelled group adds label (sm/semibold/secondary) with error
  `*`, helper (sm/tertiary), error (sm/error, hides helper, announces);
  field text base/`text` with primary caret, placeholder tertiary, error
  recolors text+caret, disabled tertiary + group opacity, read-only
  secondary without caret, branded focus ring on `:focus-visible`.
- Guard hooks contract: `mx_text_field.dart` may own its controller (rule
  exclusion); every consumer must go through `useMx*` hooks under
  `lib/presentation/shared/hooks/` (child B); hooks stay
  presentation-only.

## Child boundaries (XL rule)

| Child | Boundary | Status |
| --- | --- | --- |
| A | `MxTextField` core at the guard path: bare + labelled anatomy, empty/filled/focus/error/disabled/read-only/multiline states, keyboard/autofill passthrough, ring without layout shift, error live region | **Done** (2026-07-19) |
| B | Hooks foundation: `flutter_hooks ^0.21.0` + `hooks_riverpod` resolving 3.3.1 (the newest line pinning riverpod 3.2.1; 3.3.2 excluded by the annotation pin — pub.dev evidence 2026-07-19), `useMxTextValue`, `useMxTextSubmitState` (trimmed-non-empty submit rule via `StringUtils`), `useMxSearchController` (trimmed query + clear; debounce arrives additively with WBS 10.x) under `shared/hooks/`; 3 HookBuilder tests | **Done** (2026-07-19) |
| C | Form-state coverage: `MxSearchField` at the guard path (pill ground at the dock height, leading glyph, clear affordance with localized label, flat variant, focus ring; dock chrome stays with 3.6) + stress suite (expansion-length input at 320px, multiline CJK, autofill wiring, 200% text scale) | **Done** (2026-07-19) |

## Scope — child A (this delivery)

Create:

- `lib/presentation/shared/widgets/inputs/mx_text_field.dart` —
  `MxTextField` per the contract above; internal controller fallback,
  focus ring reserving its stroke (no layout shift), `Semantics(textField,
  label ?? placeholder)`, error `liveRegion`.
- `lib/core/theme/extensions/app_text_styles.dart` — `fieldLabel` role
  (kit `.field-group__label` sm/semibold).
- `test/.../inputs/mx_text_field_test.dart` — 9 tests over the state
  matrix (bare/labelled, onChanged, required star, error-over-helper +
  recolor + live region, disabled, read-only, multiline, keyboard type,
  focus ring without shift).

Out of scope for child A: hooks (B), search field and stress-state suite
(C), form-level submit orchestration (3.9 async runner).

## Acceptance and test procedure

`AC-WBS-3.3-01` (child A portion): every kit state renders with exact
token colors; error state hides helper and announces; keyboard/autofill
parameters pass through; ring reserves space. Full canonical gate passes.

`TEST-WBS-3.3-01` (child A portion): `mx_text_field_test.dart` in every
gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Child B promotion requires child A merged and green; the WBS `3.3` row
  stays Ready until child C completes.
