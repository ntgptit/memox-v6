# WBS 4.4 — DAO layer implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — children A, B Done (2026-07-19); C pending |
| Owner/domain | Data / Persistence |
| Depends on | `4.2`, `4.3` — Done (PRs #42–#46) |
| Decision gates | DG-06 (ADR-004) |
| Acceptance | `AC-WBS-4.4-01` |
| Test | `TEST-WBS-4.4-01` |

## Canonical inputs

- WBS 4.4: one responsibility per DAO; paged/stream queries; no raw SQL
  outside `data/database` paths.
- Owner SQL-first directive: DAO queries are **named SQL queries in
  `.drift` files** (`lib/data/database/queries/*.drift`), attached to
  one `@DriftAccessor` class per aggregate — Dart never embeds SQL
  strings.
- Business ownership map (`docs/business/README.md`): translations,
  tags and audio refs are Flashcard-owned child content, so they belong
  to the Flashcard aggregate's DAO.

## Child boundaries (one child per PR)

| Child | Domain | DAOs |
| --- | --- | --- |
| **A** | Content | `LanguagePairDao`, `DeckDao`, `FlashcardDao` |
| **B** | Progress and rhythm | `LearningProgressDao`, `StudyAttemptDao`, `PreferenceDao`, `StudyGoalDao`, `StreakDao` |
| **C** | Study-session runtime | `StudySessionDao`, `SessionSnapshotDao`, `SessionCheckpointDao` |

Shared rules for every child:

- One `daos/<name>_dao.dart` per aggregate responsibility; its SQL lives
  in `queries/<group>.drift` and the accessor mixin exposes the typed
  methods drift generates.
- Reads that feed UI ship as `Selectable` — `.watch()` gives the stream
  contract, `LIMIT :limit OFFSET :offset` gives paging.
- Listing queries exclude soft-deleted rows; lifecycle transitions
  (hide, soft-delete, restore, move) are explicit UPDATE queries so the
  4.3 triggers guard them.
- DAOs stay mechanical: no interval/transition/business rules — those
  belong to domain policies and repository contracts (4.6).

## Child A — content DAOs (Done, 2026-07-19)

- `queries/{language_pairs,decks,flashcards}.drift` — named queries:
  inserts with explicit column lists; find-by-id/key; root/child deck
  listings; deck rename/move/delete; card paging + stream per deck with
  soft-deleted rows excluded; hide/soft-delete/restore/move card;
  translation/tag/audio-ref child-content queries (list per card,
  attach/detach with cascade-backed deletes).
- `daos/{language_pair_dao,deck_dao,flashcard_dao}.dart` —
  `@DriftAccessor` shells over those files, registered in
  `@DriftDatabase(daos: …)`.
- `test/data/database/content_daos_test.dart` — DAO contract tests:
  insert/find round-trips, watch streams emitting on change, page
  boundaries, soft-delete exclusion + restore, child-content
  attach/list/detach, move guarded by the 4.3 triggers.

## Child B — progress and rhythm DAOs (Done, 2026-07-19)

- `queries/{learning_progress,study_attempts,preferences,study_goals,streaks}.drift`
  — named queries: progress insert/find plus `updateProgressGuarded`
  (optimistic revision guard; the policy decides values, the DAO only
  writes them); due paging/count joining flashcards to exclude future,
  hidden and soft-deleted cards; append-only attempt evidence (no
  UPDATE/DELETE defined) with idempotency-key lookup and newest-first
  paging; preference upsert (`ON CONFLICT DO UPDATE`); goal config +
  per-local-day bucket upsert; idempotent streak-day recording
  (`ON CONFLICT DO NOTHING`) with range/paged listings.
- `daos/{learning_progress,study_attempt,preference,study_goal,streak}_dao.dart`
  — `@DriftAccessor` shells registered in `@DriftDatabase(daos: …)`.
- `test/data/database/progress_daos_test.dart` — revision-guard
  accept/reject, due-queue exclusions, idempotency lookup + paging,
  upsert overwrite-in-place, day-bucket met state, streak idempotency
  and range order.

## Acceptance and test procedure

`AC-WBS-4.4-01`: every aggregate has exactly one DAO; all SQL lives in
`.drift` files; UI-facing reads are streamable and pageable;
soft-deleted rows never leak from listing queries; no DAO reimplements
domain rules.

`TEST-WBS-4.4-01`: per-child DAO suites in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success per child: PR merged with the canonical gate green; register
  updated. 4.4 flips Done when C merges; 4.5 (mappers) may proceed in
  parallel once A exists.
