# WBS 3.9 — Async/action infrastructure implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Flutter UI + State / Shared `Mx*` |
| Depends on | `3.7` — Done |
| Decision gates | DG-02, ADR-007 |
| Acceptance | `AC-WBS-3.9-01` |
| Test | `TEST-WBS-3.9-01` |

## Canonical inputs

Guard-named APIs (the rules already reference these exact symbols/paths):

- `AppAsyncBuilder` — the only legal `AsyncValue` renderer in feature/shell
  UI (`use_app_async_builder` bans direct `.when`).
- Shared action runner — controllers may not hand-write
  `state = AsyncError<void>(...)` (`action_controllers_use_runner`).
- `MxActionErrors.failureOf/messageOf` at
  `shared/viewmodels/mx_action_errors.dart`
  (`action_error_extraction_via_helper` / `action_error_message_via_helper`).
- `MxAsyncDraft.currentValue` at `shared/viewmodels/mx_async_draft.dart`
  (`async_draft_via_extension`).
- ADR-005/1.5 failure taxonomy: UI only ever sees `AppFailure`.

## Scope

Create:

- `shared/viewmodels/mx_async_draft.dart` — the draft extension.
- `shared/viewmodels/mx_action_runner.dart` — `runMxAction` (thrown
  errors → `AppFailure`-carrying `AsyncError`, success → `AsyncData`) and
  `listenMxAction` — the typed one-shot effect listener (failure/success
  delivered exactly once per transition via `ref.listen`).
- `shared/viewmodels/mx_action_errors.dart` — `failureOf` +
  localized `messageOf` (extends with each new failure variant).
- `shared/viewmodels/mx_async_builder.dart` — `MxAsyncBuilder` (the
  "AppAsyncBuilder" the guard mandates, carried with the `Mx` naming
  contract and placed in viewmodels because shared widget dirs stay
  provider-free per `no_app_wiring`): data/loading/error/retry
  rendering over the 3.7 primitives: announced spinner default, error
  banner with optional retry, custom builders, and retained
  data-on-refresh (`skipLoadingOnRefresh`) as the default.

Out of scope: generated command notifiers and provider lifecycle rules
(1.11), snackbar service (3.13), feature wiring (5.x).

## Acceptance and test procedure

`AC-WBS-3.9-01`: every guard-named symbol exists at its expected path
with the mandated semantics; all copy arrives localized by parameter;
errors surface only as `AppFailure`. Full canonical gate passes.

`TEST-WBS-3.9-01`: `mx_async_infrastructure_test.dart` (10 tests: draft,
runner mapping, error helpers, builder states + retained refresh,
listener transition semantics) in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `3.9` Done, then author `3.10`
  (first-learning shared composites) next.
