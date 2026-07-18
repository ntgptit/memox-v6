# WBS 3.2 — `MxButton` family implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `3.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.2-01` |
| Test | `TEST-WBS-3.2-01` |

## Canonical inputs

- Kit `components/core/MxButton.prompt.md` (frozen contract) and the
  `.btn` rules in `components.css`: variants primary/secondary/contrast/
  outline/ghost + `danger` + sizes sm/md/lg + `block`; sm keeps the 48px
  hit target around its 40px visual; glyphs at font-size-lg; hover fills
  (primary→primary-strong, secondary→state-selected, outline/ghost→
  state-hover); disabled at opacity-disabled.
- Guard: shared doc contract; token access only via context accessors
  (`no_direct_color_typography_tokens`); no `!` assertions in
  presentation; `MxTappable` as the only ink surface.
- WBS row note — "loading": the kit contract is explicit ("No built-in
  loading state — the parent disables the button and shows progress
  while submitting"); the row's loading state maps to that parent-driven
  pattern, not a spinner prop. Recorded here, not silently decided.

## Scope

Create:

- `lib/presentation/shared/widgets/mx_button.dart` — `MxButton` over
  `MxTappable` (focus ring/press layers inherited): variant/danger color
  resolution from `context.colors`, size metrics from tokens, label
  styles via the new `AppTextStyles.buttonSm/button/buttonLg` roles
  (kit `.btn` bold at sm/base/md), leading icon at the subtitle size
  (kit type-scale reuse), `block`, disabled opacity. Fill paints via
  `Ink` so tappable overlays stay visible.
- `test/presentation/shared/widgets/mx_button_test.dart` — 10 tests:
  per-variant fills/borders/foregrounds, danger, disabled opacity +
  no-tap, sm hit-target vs visual, lg height, block width (focus-ring
  reservation documented), icon size/color, hover fill swap with a real
  mouse gesture.

Modify: `app_text_styles.dart` (+ button label roles).

Out of scope: `MxLink`/`MxIconButton`/`MxFab` (3.6/3.8), snackbar action
styling (3.13), golden catalog (3.11/3.12).

## Acceptance and test procedure

`AC-WBS-3.2-01` is true only when:

1. Every variant × size × state matches the kit CSS values through token
   accessors only (no direct token-file imports, no `!` assertions).
2. sm preserves the 48px target; block never fixes width to the label.
3. Hover/press/focus/disabled behaviors are test-verified.
4. Full canonical gate passes with zero guard errors.

`TEST-WBS-3.2-01`: `mx_button_test.dart` (10 tests) in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `3.2` Done, then author `3.3`
  (`MxTextField` and form foundation, XL — child boundaries) next.
