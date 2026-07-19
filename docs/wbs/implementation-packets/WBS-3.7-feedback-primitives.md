# WBS 3.7 — First-learning feedback primitives implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `3.2`–`3.5` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.7-01` |
| Test | `TEST-WBS-3.7-01` |

## Canonical inputs

Kit prompts + CSS (frozen): `MxProgress` (4px bar on the muted track with
primary fill, determinate/indeterminate, inline spinner), `MxBanner`
(soft-tint tones info/success/warning/error with paired on-soft
foregrounds, tone glyph, title/base-bold + body/sm + trailing action),
`MxDialog` (scrim + raised panel capped at size-5xl, radius-2xl,
shadow-lg, title as accessible name, right-aligned actions with the
documented wrap-on-narrow behavior), `MxSheet` (raised ground, top-2xl
radii, 48×4 handle, section-title heading, 88% height cap, bottom safe
area).

## Scope

Create `mx_progress.dart`, `mx_banner.dart`,
`dialogs/mx_dialog.dart` (+`showMxDialog`),
`bottom_sheets/mx_sheet.dart` (+`showMxSheet`); token layer gains
`AppBorderRadii.sheetTop`. All copy arrives by slot/parameter — the
loading/error/offline states these primitives express are wired to
async state by 3.9 (`AppAsyncBuilder`) and consumed by
create/start/study/retry flows in 5.x.

Guard findings resolved during development: positional-param helper
removed (callers pass `MxText` bodies), `!` promotion in progress,
dialog action Row → Wrap (kit 200%-scale rule), sheet top radius named
in the token layer.

## Acceptance and test procedure

`AC-WBS-3.7-01`: every tone/variant/state matches kit values through
token accessors; progress always announces; dialog resolves/dismisses
through the route result; sheet honours the height cap and safe area.
Full canonical gate passes.

`TEST-WBS-3.7-01`: `mx_feedback_test.dart` (8 tests) in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `3.7` Done, then author `3.9`
  (async/action infrastructure) next; `3.8` selection primitives follow
  the critical-path items.
