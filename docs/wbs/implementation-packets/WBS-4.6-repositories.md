# WBS 4.6 — Repository ports/implementations packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — children A, B, C shipped one PR each |
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

## Child C — study-session repository (Done, 2026-07-19)

- Port `StudySessionRepository` + `DriftStudySessionRepository`,
  owner of the three session operations:
  - **Op 2** `startSession`: session row + card snapshots + initial
    round order in one transaction; the session id is the idempotency
    key; a competing active session aborts on the single-active index
    (`ConflictFailure('duplicate')`) and rolls the snapshots back.
  - **Op 3** `saveAttemptWithCheckpoint`: attempt evidence and the
    resumable checkpoint persist together before presentation
    advances; the attempt idempotency key absorbs replays without
    overwriting the stored checkpoint.
  - **Op 5** `finalizeSession`: terminal state transition + goal/streak
    contribution events in one transaction behind the revision guard;
    a replay that finds the session already in the requested terminal
    state returns success (contributions committed with the original),
    any other stale write raises `ConflictFailure('revision')`.
- Relearn queue rides the port with injected `recordedAt`.
- `test/data/repositories/session_repository_test.dart` — atomic +
  idempotent start, competing-session rollback, attempt/checkpoint
  replay absorption, exactly-once finalize with contributions,
  stale-revision conflict, relearn dedup.

## Acceptance and test procedure

`AC-WBS-4.6-01`: every aggregate exposes a domain port whose
implementation composes DAOs + mappers inside data-layer transactions;
atomic operations commit or roll back as one; conflicts and corruption
surface only as taxonomy failures with stable codes; no Drift type
crosses the port boundary.

`TEST-WBS-4.6-01`: per-child repository contract suites in every gate.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Completed 2026-07-19: A (#51), B (#52), C closed the packet —
  `4.7` (migration system) and `4.8` (DI graph) are unblocked.
