# WBS 1.11 — Riverpod foundation implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Architecture / State management |
| Depends on | `1.3`, `1.6`, `1.10` — Done |
| Decision gates | ADR-005 |
| Acceptance | `AC-WBS-1.11-01` |
| Test | `TEST-WBS-1.11-01` |

## Canonical inputs

- WBS 1.11: generated provider lifecycle/family/keepAlive rules,
  command/effect pattern, cancellation/invalidation/retry contract and
  override tests.
- The `memox` guard `state_management` rules (generated-only providers,
  keep-alive infrastructure in `lib/app/di/**`, `ref.listen` side
  effects, no broad invalidation) — the contract makes the enforced
  rules explicit.
- The 3.5 command layer (`MxActionRunner`, `MxActionErrors`,
  `MxAsyncDraft`) already carries the command/effect pattern.

## Scope

- `docs/architecture/riverpod-foundation.md` (**Accepted**) — the
  written contract: generated-only providers; lifecycle by role
  (infrastructure keep-alive in `lib/app/di/`, screen state
  autoDispose); value-equal family keys; ports over direct
  clock/random/id reads; `MxActionRunner` command pattern with
  `ref.listen` effects; invalidation as the one refresh/retry
  mechanism with no internal retry loops.
- `lib/app/di/core_providers.dart` — the first generated
  infrastructure providers: `appClockProvider`, `idGeneratorProvider`
  (`@Riverpod(keepAlive: true)`); the 4.8 DI graph adds
  database/repository providers beside them.
- `test/app/di/riverpod_foundation_test.dart` — contract tests over a
  generated test-local family: keep-alive persistence + override
  substitution with the 1.10 fakes, per-key family resolution and
  autoDispose reclamation on last-listener close, mid-flight
  invalidation discarding the stale result, and invalidate-as-retry
  recovering after a failure.

## Acceptance and test procedure

`AC-WBS-1.11-01`: the provider contract is written and accepted; core
infrastructure providers exist generated and keep-alive; lifecycle,
cancellation, invalidation, retry and override behavior are all
test-proven against the contract.

`TEST-WBS-1.11-01`: `riverpod_foundation_test.dart` in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `1.11` Done — `4.8` (DI graph)
  is unblocked and next.
