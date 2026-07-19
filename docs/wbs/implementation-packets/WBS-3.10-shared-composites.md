# WBS 3.10 — First-learning shared composites implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `3.2`–`3.9` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.10-01` |
| Test | `TEST-WBS-3.10-01` |

## Canonical inputs

- Kit `_shared/ConfirmDialog.md` (frozen): scrim + dialog with tone-tinted
  header icon (`warning`/`error`/neutral), title/body, Cancel/Confirm pair;
  carries no copy of its own — used by six sites across study-session,
  deck-settings and languages.
- Kit `_shared/SelectSheet.md` (frozen): single-select option list in a
  bottom sheet — uppercase title, icon+label rows, primary-tinted check on
  the active row; owns the pattern shared by mode-picker scope, library
  sort and settings value pickers.

## Scope

Create:

- `dialogs/mx_confirm_dialog.dart` — `showMxConfirmDialog(...) →
  Future<bool>` over `showMxDialog`: optional tone-tinted icon, caller-
  supplied copy, ghost Cancel + primary Confirm (error tone forces the
  danger fill); cancel/barrier resolve `false`.
- `bottom_sheets/mx_select_sheet.dart` — `showMxSelectSheet<K>(...) →
  Future<K?>` over `showMxSheet`: overline title, `MxSelectOption<K>`
  rows (icon + label + accent check on `selected`), tap resolves the key,
  dismiss resolves `null`. Feature-free generics.

Recorded boundary — the WBS row also names ActionCallout, breadcrumb and
study-prompt patterns; the kit has **no `_shared` spec** for them (their
anatomy lives inside owning screen specs), so inventing feature-free APIs
now would violate the values-follow-kit rule. They land with their first
consumers: ActionCallout with 5.2.3, breadcrumb with 6.2, study prompt
with 5.6.4 — promoted into `_shared` widgets there, then swept by the
3.11 catalog.

## Acceptance and test procedure

`AC-WBS-3.10-01`: both composites match their kit specs through the
existing primitives, carry zero hardcoded copy and expose feature-free
APIs. Full canonical gate passes.

`TEST-WBS-3.10-01`: `mx_composites_test.dart` (4 tests: confirm/cancel/
barrier semantics, tone tint + danger forcing, selected check, key
resolution + null dismiss) in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `3.10` Done. Next: `3.12`
  (minimal `Mx*` first-learning gate) once `4.10` prerequisites allow, or
  the wave-4 data foundation begins with `4.1`.
