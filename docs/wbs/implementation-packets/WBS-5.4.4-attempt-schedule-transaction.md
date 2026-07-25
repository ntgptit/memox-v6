# WBS 5.4.4 — Attempt/schedule transaction

- Status: **Done** (children A, B and C, 2026-07-25)
- Size: XL — split into children per §6.2 ("for an XL row, the packet must
  split child boundaries even when the stable WBS ID remains unchanged")
- Depends on: `5.4.3` (the pure policy that computes what this row persists)
- Owns: `SRS8-011` (idempotent replay), `SRS8-012` (stale-revision conflict),
  and the `srsActivatedAt`/`lastReviewedAt` schema addition

## Why this row exists

`5.4.3` built the policy that decides a card's next box, due date and counters.
Nothing wrote them. This row is the only writer of what that policy computes,
and it must write the evidence and the schedule as one commit — a stored
attempt with no schedule, or a schedule with no evidence, are both corruption.

## Children

| Child | Boundary | Status |
| --- | --- | --- |
| A | Persist the policy's two timestamps: schema v2, migration, and the round trip through port → repository → DAO | **Done** (2026-07-25) |
| B | Concurrent-writer coverage: `SRS8-012` under genuine interleaving, not just a stale `expectedRevision` argument | **Done** (2026-07-25) |
| C | Terminal-scheduling exactly-once across process restart — the idempotency key survives a crash between attempt insert and schedule write | **Done** (2026-07-25) |

The atomic transaction, the idempotency dedupe and the guarded-revision update
were already implemented under `5.4.3`'s wiring
(`drift_learning_progress_repository.dart`); children B and C harden and prove
them rather than build them.

## Child A — what landed

`SrsSchedule` returned `lastReviewedAt` and `srsActivatedAt` from the first
commit of the policy, and `ApplyTerminalOutcomeUseCase` dropped both on the
floor with a comment saying so: schema v1 had no column for either. Every
terminal grade recomputed a card's activation instant and its last-review
instant, then discarded them.

- `learning_progress` gains `srs_activated_at` and `last_reviewed_at`
  (schema v2, the repo's **first** real migration — v1 was create-only).
- `updateProgressGuarded` writes both inside the existing guarded update, so
  they are covered by the same revision check and the same transaction.
- The port, the Drift repository, the mapper and the domain entity all carry
  the two values end to end.

### Defect found and fixed in the same change

`Srs8BoxPolicy.applyTerminalGrade` took `srsActivatedAt` as an **optional**
parameter defaulting to `null`, and no caller in `lib/` or `test/` ever passed
one. That was inert only while nothing persisted the value. The moment child A
began storing it, the default would have written NULL over a real activation
instant on **every grade** — silently resetting the one field §3 says never
moves.

The parameter existed because `LearningProgress` had no field to read from.
Now that it does, the parameter is gone and the policy reads
`current.srsActivatedAt`, which removes the choice rather than documenting it.
Two tests hold the line: a later grade carries the activation through, and a
pre-v2 row keeps NULL instead of acquiring one.

### The migration deliberately does not backfill

Rows written under v1 were activated at an instant nobody recorded. The nearest
available column, `updated_at`, is the *last* review, not the first activation.
Writing it would not be a migration but a fabrication, and every statistic later
built on activation age would inherit it. `migration-policy.md` rule 6 —
"never infer a business-policy migration from a schema version alone" — requires
leaving them NULL, and `box` disambiguates the two meanings of NULL for readers.

## Children B and C — what landed

Both are coverage, not new mechanism: the transaction, the dedupe and the
guarded update already existed. The question each answers is whether the
property is real or incidental.

**B — the stale revision now arises instead of being asserted.** The existing
conflict test passed `expectedRevision: 9`, an impossible literal. That proves
the guard rejects a bad argument, not that it fires in the situation it exists
for. The new test has both writers read the card's *actual* revision first —
as two devices or two tabs would — and race on it. Exactly one commits, the
other raises `ConflictFailure`, the revision advances by one, and the loser
leaves no evidence row behind, so a retry can re-run cleanly.

**C — the dedupe is a property of the store, not of the object graph.** In one
connection, a replay being deduped is indistinguishable from an in-memory cache
doing the work. The restart harness is file-backed, so closing and reopening
gives a new connection and a new repository over the same store. A replayed key
after restart does not re-grade the card (deliberately with a *different*
schedule, so a failure would be visible rather than coincidentally identical),
and — its counterpart — a genuinely new key after restart still applies, so
dedupe has not become "reject everything after a restart".

### Defect found while reviewing this path

Both `applyScheduledOutcome` and `saveAttemptWithCheckpoint` treated any stored
idempotency key as a replay and returned success. The key column is **globally**
unique, so a key minted for one card and reused for another would be read as a
replay of that other card's write: the grade would vanish with no write and no
error, and the caller would believe it succeeded — silent loss, the worst
failure mode available.

It is unreachable today: keys are card-scoped by construction
(`terminal:<session>:<card>`, and the stage key's card position). Both paths now
verify the stored attempt's `cardId` and raise
`ValidationFailure(idempotencyKey, 'card-mismatch')` otherwise, so if key
generation ever changes the result is a typed failure rather than a lost review.

## Evidence

- `test/data/database/migration_test.dart` — v2 snapshot matches a fresh
  create; the v1 → v2 upgrade adds both columns; a v1 row survives with its box
  intact and both timestamps NULL.
- `test/data/repositories/progress_repositories_test.dart` — both timestamps
  round-trip through the store; a later grade advances the review instant but
  leaves the activation instant alone.
- `test/domain/learning_progress/srs_8_box_policy_test.dart` — the activation
  pass-through and the NULL-preserving cases above.
- `drift_schemas/drift_schema_v2.json` and
  `test/data/database/generated_migrations/schema_v2.dart` (policy rule 1).
- `test/data/repositories/progress_repositories_test.dart` — two writers on the
  same observed revision; a key already used by another card fails typed.
- `test/data/repositories/srs_exactly_once_restart_test.dart` — a replay after
  restart does not re-grade; a new key after restart still applies.
