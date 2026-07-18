# WBS 3.5 — `MxScaffold` and content shells implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **Ready** — child A Done (2026-07-19); children B–C pending |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `2.10`, `3.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.5-01` |
| Test | `TEST-WBS-3.5-01` |

## Canonical inputs

- Kit `components/surfaces/MxScaffold.prompt.md` (frozen): root phone
  shell with app bar / scrolling body / bottom nav / optional FAB slots;
  once per screen, never nested; `flush` drops body side padding; honours
  top/bottom safe areas; body handles empty/overflow/short viewports;
  logical padding for RTL mirroring.
- Guard screen-shell rules: page gutter only via
  `MxContentShell`/`MxScaffold` family (`no_manual_page_gutter`), no
  redundant nested shells, feature screens use the `Mx*Scaffold` family
  (`use_mx_scaffold_family`), no raw `Scaffold` in features.
- Responsive contract (2.8): gutters per class, `ContentSurface` caps.

## Child boundaries (XL rule)

| Child | Boundary | Status |
| --- | --- | --- |
| A | `MxContentShell` (class-driven gutter, optional centered width cap, flush) + `MxScaffold` core (slots, safe areas, default body scrolling with an opt-out for self-scrolling bodies) | **Done** (2026-07-19) |
| B | Constrained shells: `MxListScaffold` (list cap, flush lazy body), `MxFormScaffold` (reading cap), `MxStudyScaffold` (study cap) preconfiguring the frame | Pending |
| C | Retained-composition and stress evidence: RTL mirroring, safe-area insets, empty/short-viewport matrix across the family | Pending |

## Scope — child A (this delivery)

Create:

- `lib/presentation/shared/layouts/mx_content_shell.dart` — gutter from
  `context.spacing` (16/24/32 by class), optional `ContentSurface` cap
  centered on wide windows, `flush` full-bleed escape.
- `lib/presentation/shared/layouts/mx_scaffold.dart` — the root shell:
  app bar/body/bottom-nav/FAB slots, top/bottom `SafeArea` (bottom owned
  by the nav slot when present), body wrapped in `MxContentShell`,
  scrolling by default (`scrollable: false` for list bodies that own
  scrolling — used by child B).
- `test/.../layouts/mx_scaffold_test.dart` — 5 tests: all slots + short-
  viewport scroll without overflow, class-driven gutter (390→16,
  1440→32), flush, study-cap centering at 1440, slotless nav behavior.

Out of scope for child A: the three constrained shells (B), RTL/safe-area
stress matrix (C), `MxContextualAppBar`/`MxBottomNav`/`MxFab` (3.6).

## Acceptance and test procedure

`AC-WBS-3.5-01` (child A portion): the frame owns gutter/caps/safe areas
per contract; bodies scroll while bars stay fixed; no raw layout values.
Full canonical gate passes.

`TEST-WBS-3.5-01` (child A portion): `mx_scaffold_test.dart` in every
gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Child B promotion requires child A merged and green; the WBS `3.5` row
  stays Ready until child C completes.
