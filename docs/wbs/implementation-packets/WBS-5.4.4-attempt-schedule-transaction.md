# WBS 5.4.4 — Attempt/schedule transaction

- Status: **In progress** (child A Done, 2026-07-25)
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
| B | Concurrent-writer coverage: `SRS8-012` under genuine interleaving, not just a stale `expectedRevision` argument | Not started |
| C | Terminal-scheduling exactly-once across process restart — the idempotency key survives a crash between attempt insert and schedule write | Not started |

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
