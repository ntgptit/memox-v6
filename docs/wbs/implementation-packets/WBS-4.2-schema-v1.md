# WBS 4.2 — Schema v1 implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — children A, B, C shipped one PR each |
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
  milliseconds named `*_at` — no unit suffix; the UTC convention is a
  header comment in each `.drift` file (owner directive, 2026-07-19); booleans are `INTEGER` with `CHECK (x IN
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

## Child B — progress and rhythm tables (Done, 2026-07-19)

- `lib/data/database/tables/progress.drift` — `study_attempts`
  (unique idempotency key, append-only evidence; `session_id` stays a
  plain column until child C creates `study_sessions`, when the FK is
  added); `learning_progress` (one row per card via unique FK, `box`
  0..8 with the accepted box/due shape as a CHECK — Box 0/8 null,
  1..7 due-dated — baseline `leitner-8-box-v1` policy identity,
  revision/counters, last terminal attempt reference); `preferences`
  as the versioned typed key/value shape schema-v1 left open (JSON value
  + explicit schema version; invalid fallback is mapper-layer read
  behavior); `daily_goals` + `goal_day_progress` (per-local-day bucket,
  unique `local_date`, timezone + target snapshots; contribution
  idempotency rides the session-finalize exactly-once contract, atomic
  operation 5); `streak_days` (unique local date, qualified
  source/version).
- `test/data/database/progress_schema_test.dart` — 7 DDL contract tests:
  table presence, one-progress-per-card, box range + box/due shape,
  baseline policy defaults, attempt idempotency-key uniqueness, unique
  local dates for goal buckets and streak days, card-delete cascade.

## Child C — study-session runtime tables (Done, 2026-07-19)

- `lib/data/database/tables/sessions.drift` — `study_sessions` (typed
  session_type/scope/state CHECKs; the selected v1 active-session policy
  is one active session app-wide, enforced by a partial unique index on
  `state = 'active'`; revision + snapshot version; `schedule_srs` flag);
  `study_session_cards` (start-of-session content/progress snapshot,
  unique per card and per order slot); `study_checkpoints` (one
  resumable position per session with failed-set/timer state, versioned);
  `study_round_orders` (deterministic seed + persisted order, unique per
  session/round); `session_relearn_items` (failed card deduplicated per
  session; learning retry namespace distinct from persistence retry).
- `study_attempts.session_id` gains its deferred FK to `study_sessions`.
- `test/data/database/sessions_schema_test.dart` — 8 DDL contract tests:
  table presence, single-active enforcement, type/scope/state CHECKs,
  session-card uniqueness both ways, checkpoint/round-order uniqueness,
  relearn dedup, the new attempts FK, session-delete cascade.

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

- Completed 2026-07-19: A (#42), B (#43), naming follow-up (#44), C
  closed the packet — 4.3 (constraints) and 4.4 (DAOs) are unblocked.
- If drift_dev rejects a DDL construct, prefer the nearest supported SQL
  form and record the deviation here — never move schema back into Dart.
