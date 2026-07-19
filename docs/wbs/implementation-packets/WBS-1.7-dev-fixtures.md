# WBS 1.7 — Developer fixtures implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Developer experience / Data |
| Depends on | `1.3` — Done; deferred until the 4.x data layer existed (sequencing note) |
| Decision gates | — |
| Acceptance | `AC-WBS-1.7-01` |
| Test | `TEST-WBS-1.7-01` |

## Canonical inputs

- WBS 1.7: seed/reset commands for empty, minimum, dense, error,
  paused-session and due-card states; never shipped in release mode.
- The migration-policy fixture list names the same states for future
  migration evidence.

## Scope

- `lib/data/dev/dev_fixtures.dart` (data layer — the seeder wipes and writes through transactions, which the guard scopes to `lib/data/**`) — `DevFixtures` over the shared
  `AppDatabase` with `reset()` (child-tables-first wipe in one
  transaction) and `seed(DevFixtureState)`:
  - `empty` — fresh install; `minimum` — one pair/deck/card at Box 0;
    `dense` — a root with three sibling decks × 25 cards (crosses the
    page size); `error` — minimum plus a corrupt preference payload
    (exercises the read fallback); `pausedSession` — active session
    with snapshot, round order and a mid-round checkpoint (the resume
    input); `dueCard` — minimum with the card due in the past.
  - **Release guard**: construction throws `StateError` in release
    builds (`kReleaseMode`), so no shipped code path can reach a
    seeder; tests pass `enabled: false` to prove the guard.
  - Deterministic fixture ids (`fix-*`) and a fixed timestamp — no
    clock or randomness.
- `test/dev/fixtures/dev_fixtures_test.dart` — the release guard plus
  per-state shape assertions and reset-to-empty.

Recorded boundary: CLI entry points (e.g. a dev menu or `dart run`
command) attach when the first consumer screen lands; the seeding API
is complete and covered now.

## Acceptance and test procedure

`AC-WBS-1.7-01`: every named state seeds deterministically through the
public data layer; reset restores empty; release builds cannot
construct the seeder.

`TEST-WBS-1.7-01`: `dev_fixtures_test.dart` in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `1.7` Done; `1.10` shared test
  infrastructure is the next deferred-1.x candidate (then `1.11`,
  unblocking `4.8`).
