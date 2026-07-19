# WBS 4.6 — Repository ports/implementations packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — children A, B Done (2026-07-19); C pending |
| Owner/domain | Data + Domain / Persistence boundary |
| Depends on | `4.4`, `4.5` — Done (PRs #47–#50) |
| Decision gates | DG-06 (ADR-004), ADR-005 failure taxonomy |
| Acceptance | `AC-WBS-4.6-01` |
| Test | `TEST-WBS-4.6-01` |

## Canonical inputs

- WBS 4.6: UseCase→Repository→DAO flow, atomic cross-table methods and
  repository contract tests.
- `schema-v1.md` "Atomic operations" 1–7: each operation declares an
  idempotency key, expected revision, conflict result and
  crash-recovery behavior in its repository contract.
- Guard: repository interface files/classes carry the `Repository`
  suffix; transactions only inside the data layer.

## Child boundaries (one child per PR)

| Child | Aggregates | Atomic operations owned |
| --- | --- | --- |
| **A** | Language Pair, Deck, Flashcard | Op 1 (create card + Box 0 progress + deck transition) |
| **B** | Learning Progress, Preferences, Study Goal, Streak | Op 4 (terminal outcome + schedule exactly once), Op 6 (reset projections) |
| **C** | Study Session (+ snapshot/checkpoint/relearn/attempts) | Op 2 (start + snapshots + order), Op 3 (attempt + checkpoint), Op 5 (finalize + contributions exactly once) |

Shared rules:

- Ports live beside their domain models (`lib/domain/<agg>/…_repository.dart`,
  `abstract interface class …Repository`); Drift-backed implementations
  in `lib/data/repositories/drift_…_repository.dart`.
- Every write runs through `mapSqliteConflicts` so uniqueness
  violations and 4.3 trigger aborts surface as `ConflictFailure`s with
  stable codes (`duplicate`, `deck-mixed-content`, `deck-cycle`,
  `missing-reference`, `revision` for guarded updates).
- Lookups return null for absent ids; flows own not-found recovery.
- Streams map row lists into domain models; no Drift type escapes.

## Child A — content repositories (Done, 2026-07-19)

- `ConflictFailure` joins the taxonomy (stable `code` + entity) with
  l10n copy; `lib/data/database/sqlite_error_mapper.dart` centralizes
  the SQLite→taxonomy translation.
- Ports: `LanguagePairRepository`, `DeckRepository`,
  `FlashcardRepository` (+ `NewCardContent` draft aggregate).
- `createCard` implements atomic operation 1: card + translations/tags/
  audio refs + initial Box 0 progress (due null) in one transaction;
  the card id is the idempotency key (retry finding it stored returns
  success); an exclusivity abort rolls everything back.
- `test/data/repositories/content_repositories_test.dart` — duplicate
  pair conflict, deck cycle/duplicate conflicts, atomic commit,
  idempotent retry, full rollback on abort, conflict-guarded lifecycle.

## Child B — progress and rhythm repositories (Done, 2026-07-19)

- Ports: `LearningProgressRepository` (operations 4 and 6),
  `PreferenceRepository`, `StudyGoalRepository`, `StreakRepository`
  (`recordDay` takes an injected `recordedAt` — repositories never read
  the clock).
- **Operation 4** `applyScheduledOutcome`: one transaction persists the
  terminal attempt evidence and applies the policy-computed schedule
  behind the revision guard. The attempt idempotency key dedupes
  replays (replay → success, no reapply); a stale revision raises
  `ConflictFailure(code: 'revision')` and the evidence insert rolls
  back with it. Box/due/counters always arrive from the SRS policy.
- **Operation 6** `resetCard`: delete + reinsert inside one transaction
  returns progress to Box 0/no due date with cleared counters and the
  baseline policy identity; card content untouched.
- Preference save encodes JSON in the data layer; reads inherit the
  mapper null-fallback. Goal day buckets upsert by unique local date;
  streak recording replays are absorbed by design.
- `test/data/repositories/progress_repositories_test.dart` —
  exactly-once apply + replay, stale-revision rollback (evidence absent
  after conflict), reset semantics, due paging/count, preference
  corruption fallback, goal/streak port round-trips.

## Acceptance and test procedure

`AC-WBS-4.6-01`: every aggregate exposes a domain port whose
implementation composes DAOs + mappers inside data-layer transactions;
atomic operations commit or roll back as one; conflicts and corruption
surface only as taxonomy failures with stable codes; no Drift type
crosses the port boundary.

`TEST-WBS-4.6-01`: per-child repository contract suites in every gate.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success per child: PR merged with the canonical gate green; register
  updated. 4.6 flips Done when C merges, unblocking 4.7 migrations and
  the 4.8 DI graph.
