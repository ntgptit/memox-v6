# WBS 4.2 — Schema v1 implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — child A Done (2026-07-19); B, C pending |
| Owner/domain | Data / Persistence |
| Depends on | `4.1` — Done (PR #41) |
| Decision gates | DG-06 (ADR-004) |
| Acceptance | `AC-WBS-4.2-01` |
| Test | `TEST-WBS-4.2-01` |

## Canonical inputs

- `docs/database/schema-v1.md` (**Accepted**): the 17-table v1 schema,
  ownership and invariants. DDL here implements that contract verbatim.
- `docs/business/flashcard/create-flashcard.md`: a card is term + primary
  meaning in Language Pair context; additional translations, tags and
  audio are optional child content.
- Owner directive (2026-07-19): **all schema SQL lives in `.drift` files**
  (`@DriftDatabase(include: …)`), never as Dart `Table` classes — DDL
  stays reviewable against `schema-v1.md` line by line.

## Child boundaries (one child per PR)

| Child | Table group | Tables |
| --- | --- | --- |
| **A** | Content | `language_pairs`, `decks`, `flashcards`, `flashcard_translations`, `tags`, `flashcard_tags`, `card_audio_refs` |
| **B** | Progress and rhythm | `learning_progress`, `study_attempts`, `preferences`, `daily_goals`, `goal_day_progress`, `streak_days` |
| **C** | Study-session runtime | `study_sessions`, `study_session_cards`, `study_checkpoints`, `study_round_orders`, `session_relearn_items` |

Shared rules for every child:

- SQL DDL in `lib/data/database/tables/<group>.drift`, included from
  `AppDatabase`; drift_dev generates row/companion classes.
- IDs are `TEXT` stable UUIDs; timestamps are `INTEGER` UTC epoch
  milliseconds named `*_utc`; booleans are `INTEGER` with `CHECK (x IN
  (0, 1))`.
- Uniqueness invariants become UNIQUE constraints/indexes; nullable-parent
  sibling uniqueness uses a partial-index pair (`WHERE parent_id IS
  NULL` / `IS NOT NULL`).
- `PRAGMA foreign_keys = ON` in `beforeOpen` (landed with child A) so FK
  contracts are enforced on every connection.
- `schemaVersion` stays `1` throughout — v1 ships as one schema; children
  only stage the DDL for review.
- Cross-table triggers/transaction checks (Deck exclusivity, SRS-write
  discipline, atomic-operation contracts) are **WBS 4.3**, not here.

## Child A — content tables (Done, 2026-07-19)

- `lib/data/database/tables/content.drift` — the seven content tables:
  normalized-pair uniqueness on `language_pairs`; deck tree with nullable
  `parent_id` and sibling-name uniqueness via partial indexes; flashcards
  own term + primary meaning, `content_version`, hidden flag and
  soft-delete timestamp; translations unique per (card, language, order);
  normalized tag uniqueness with `ON DELETE CASCADE` join cleanup; audio
  refs carry asset/provider metadata only (no player state).
- `lib/data/database/app_database.dart` — includes the `.drift` file and
  enables `PRAGMA foreign_keys = ON` in `beforeOpen`.
- `test/data/database/content_schema_test.dart` — DDL contract tests over
  in-memory executors: table presence, normalized-pair uniqueness, FK
  enforcement, root/child sibling-name collisions (and the allowed
  same-name-under-different-parent case), translation order uniqueness,
  tag-join cascade on card delete.

## Acceptance and test procedure

`AC-WBS-4.2-01`: every `schema-v1.md` table exists in a `.drift` file with
its required keys and uniqueness/FK invariants expressed as SQL
constraints; the generated database opens at `schemaVersion 1` with
foreign keys enforced; no Dart `Table` classes. Cross-table behavioral
invariants remain with 4.3.

`TEST-WBS-4.2-01`: per-child schema contract suites
(`content_schema_test.dart`, then progress/session equivalents) in every
gate. Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success per child: PR merged with the canonical gate green; register
  evidence updated. 4.2 flips Done when C merges, unblocking 4.3
  (constraints) and 4.4 (DAOs).
- If drift_dev rejects a DDL construct, prefer the nearest supported SQL
  form and record the deviation here — never move schema back into Dart.
