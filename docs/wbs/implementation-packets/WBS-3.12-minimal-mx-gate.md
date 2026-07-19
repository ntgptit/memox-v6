# WBS 3.12 — Minimal `Mx*` first-learning gate (review packet)

| Field | Value |
| --- | --- |
| Status | **Done — gate PASSED** (2026-07-19) |
| Owner/domain | Design system / QA |
| Depends on | `3.1–3.7`, `3.9`, `3.10`, `4.10` — Done (see exception below for `3.8`) |
| Decision gates | Follows the 4.10 foundation gate; gates the wave-5 feature UI |
| Acceptance | `AC-WBS-3.12-01` |
| Test | `TEST-WBS-3.12-01` |

## Gate scope

Per the WBS row, only the APIs/states used by the first-learning
journey — Language Pair → Deck → Card → Picker → five stages → Result —
must be documented and pass widget/golden/a11y tests. Later catalog
variants explicitly do not block this gate.

## Journey → component matrix (all shipped, documented, tested)

| Journey need | `Mx*` components | Test evidence |
| --- | --- | --- |
| Typography/icons/spacing | `MxText`, `MxIcon`, `MxGap`, `MxDivider` | `mx_foundation_test.dart` |
| Create pair/deck/card forms | `MxTextField` (+ `useMxTextEditingController`), validation states | `inputs/mx_text_field_test.dart`, `form_stress_test.dart`, `hooks/mx_hooks_test.dart` |
| Primary/secondary actions | `MxButton` (variants, disabled), `MxIconButton`, `MxFab`, `MxTappable` | `mx_button_test.dart`, `mx_navigation_test.dart` |
| Lists and pickers | `MxList`, `MxIconTile`, `MxCard`, `MxSectionHeader`, `MxSelectSheet`/`MxSheet` | `mx_list_icon_tile_test.dart`, `mx_card_test.dart`, `mx_section_header_test.dart`, `mx_composites_test.dart` |
| Discard/confirm prompts | `MxDialog`, `MxConfirmDialog` (320-cap action wrap) | `mx_composites_test.dart`, `mx_feedback_test.dart` |
| Stage progress + errors | `MxProgress`, `MxBanner` | `mx_feedback_test.dart` |
| Shells and navigation | `MxScaffold`, `MxContentShell`, constrained scaffolds, `MxContextualAppBar`, `MxBottomNav` | `layouts/*_test.dart`, `shell_stress_test.dart`, `mx_navigation_test.dart` |
| Async states end to end | `MxAsyncBuilder`, `MxActionRunner`, `MxActionErrors`, `MxAsyncDraft` | `viewmodels/mx_async_infrastructure_test.dart` |

- **Docs**: every shared widget carries the guard-enforced doc contract
  (Purpose/Use when/Do not use when/Category/Public API) — 0 doc
  warnings since 1.8.
- **Goldens**: the committed responsive golden suite renders the
  foundation composition at the kit widths in light/dark
  (`test/core/theme/responsive/goldens/`, 390 baseline included).
- **A11y**: semantics assertions run inside the foundation, feedback,
  list and navigation suites (labels, roles, merged-label lookups);
  text-scale stress in the form/shell stress suites.

## Recorded exceptions (do not block this gate)

- `3.8` selection/control primitives (chip, segmented, switch, badge,
  avatar, link): **unused by the first-learning journey** — no screen
  in Language Pair→…→Result consumes them. They land post-gate with
  `3.11/3.13/3.14` per the sequencing note.
- Study-stage composites (shared study shell) are owned by `5.6.4`;
  ActionCallout/breadcrumb/study-prompt land with their first consumers
  (5.2.3/6.2/5.6.4) — boundaries recorded in their 3.x packets.

## Acceptance and test procedure

`AC-WBS-3.12-01`: every component the first-learning journey consumes
is shipped with contract docs, widget tests, golden coverage at the
kit widths and semantics assertions; exceptions are named and owned.
**All satisfied 2026-07-19.**

`TEST-WBS-3.12-01`: the shared-widget suites named in the matrix, in
every gate run.

## Failure and completion

- Gate PASSED. The wave-5 critical path opens at `5.1` (Language Pair
  feature) in dependency order.
