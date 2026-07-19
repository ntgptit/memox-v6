# WBS 3.6 — Navigation primitives implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `3.2`, `3.5` — Done |
| Decision gates | DG-02, DG-05, ADR-006 |
| Acceptance | `AC-WBS-3.6-01` |
| Test | `TEST-WBS-3.6-01` |

## Canonical inputs

- Kit prompts + CSS (frozen): `MxIconButton` (`.icon-btn` 48 round,
  transparent/filled/primary, sm 36 with 48 hit inset),
  `MxFab` (`.fab` 56 primary fill, radius-xl extended / round icon-only,
  shadow-fab), `MxBottomNav` (`.bottom-nav` 80 on surface + shadow-nav;
  56×30 tonal pill, xs labels, brighter-active rule, 2–5 items down to
  320px), `MxContextualAppBar` (the ONE shared top bar: root /
  root-contextual / child-with-Back variants, 56 compact),
  `MxSearchDock` (elevated pill over the 3.3 search field, trailing
  slot, flat variant).
- Guard `header_actions_use_toolbar_icon_buttons` →
  `MxIconButton.toolbar(...)` preset.

## Scope

Create `mx_icon_button.dart`, `mx_fab.dart`, `mx_bottom_nav.dart`,
`mx_contextual_app_bar.dart`, `mx_search_dock.dart`; extend
`MxSearchField` with the additive `trailing` slot and `AppTextStyles`
with `navLabel`/`boldWeight`. All grounds/foregrounds/dimensions from
tokens via context accessors; every interactive surface rides
`MxTappable`.

Recorded boundaries:

- The root-contextual **on-scroll collapse** is a screen composition
  owned by Today (WBS 5.7); this bar renders the static caption+title
  form (56, or the kit's compatibility `appbar-lg` height when a
  context line is present).
- **Rail adaptation**: `context.layout.usesNavigationRail` (2.8) selects
  bottom nav vs rail; the rail presentation itself lands with the shell
  wave that first needs it (3.12 minimal gate covers compact-first
  screens).

## Acceptance and test procedure

`AC-WBS-3.6-01`: every variant×state matches kit values through token
accessors; icon-only surfaces always carry localized semantics; the
bottom nav holds 5 items at 320px; Back is the quiet toolbar preset.
Full canonical gate passes.

`TEST-WBS-3.6-01`: `mx_navigation_test.dart` (12 tests) in every gate.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `3.6` Done, then author `3.7`
  (first-learning feedback primitives) next.
