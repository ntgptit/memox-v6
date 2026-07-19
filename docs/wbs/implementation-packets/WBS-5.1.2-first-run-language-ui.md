# WBS 5.1.2 — First-run language UI implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Language Pair / Presentation |
| Depends on | `3.12` gate, `5.1.1` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.1.2-01` |
| Test | `TEST-WBS-5.1.2-01` |

## Canonical inputs

- `create-language-pair.md`: two-step selection; searchable pickers
  with long-name support (distinguishing part never ellipsizes); save
  disabled until both selected; duplicate offers the existing pair;
  save failure keeps the draft; en/vi.
- The 3.12 minimal Mx set; the Riverpod foundation contract.

## Scope — the first feature screen

- Route `/first-run/language` (`RoutePaths`/`RouteNames` constants;
  feature routes composed into `app_router` via
  `presentation/features/language_pair/routes/` — the router never
  imports feature screens directly).
- `viewmodels/first_run_language_viewmodel.dart` — generated use-case
  providers over the DI graph, the two-selection **draft notifier**
  (state survives a failed save by design) and the **save command**
  (`runMxAction`): create → adopt-existing-on-duplicate → persist the
  selection as the active pair.
- `widgets/language_select_sheet.dart` — searchable picker over
  `MxSheet` + `MxSearchField` (feature-level composition; the shared
  `MxSelectSheet` stays frozen): native name leads, English reference
  follows, live filtering with an empty-search state.
- `screens/first_run_language_screen.dart` — `ConsumerWidget` (no
  stateful widgets in features): two required selector fields, the
  `MxBanner` failure surface via `MxActionErrors`, continue disabled
  until complete and while saving, success navigating home through
  `listenMxAction` (`ref.listen` effect contract).
- New en/vi copy: 10 keys (title/subtitle, labels, placeholder, search
  hint + clear + empty, continue, failure title).
- `test/presentation/features/language_pair/first_run_language_screen_test.dart`
  — 5 widget tests over the real graph (in-memory database override):
  disabled-until-complete, sheet search filtering + empty state, save
  persisting pair + selection then navigating, duplicate adopted (one
  row, existing id selected), failure banner with the draft kept.

Recorded boundaries:

- The first-run redirect (fresh install → this screen before
  Today/Library) is navigation-guard scope, wired with the Today owner
  (5.7); the route and screen are live now.
- Light/dark + adaptive golden evidence and E2E coverage belong to
  `5.1.3`.

## Acceptance and test procedure

`AC-WBS-5.1.2-01`: both selectors required and searchable; long names
readable; duplicates resolve to the existing pair; failures keep the
draft and show mapped copy; success selects the pair and navigates;
all copy through l10n in en/vi.

`TEST-WBS-5.1.2-01`: the screen widget suite in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `5.1.2` Done; `5.1.3`
  (tests/evidence) completes the 5.1 block next.
