# Drift schema v1

- Status: **Accepted**
- Schema version: `1`
- Owner: Data
- Architecture: [ADR-004](../architecture/adr/ADR-004-local-persistence-platforms.md)

## Column conventions

Timestamp columns are named `*_at` (no unit/timezone suffix) and store UTC
epoch milliseconds; each `.drift` file documents this in a header comment.
Local-day business rules use explicit `local_date` + `timezone_id` columns.

## Tables and ownership

| Table | Owner | Required keys and invariants |
| --- | --- | --- |
| `language_pairs` | Language Pair | Stable ID; normalized learning/native pair unique; timestamps UTC |
| `decks` | Deck | Stable ID; nullable `parent_id`; `language_pair_id`; unique normalized sibling name; no cycles |
| `flashcards` | Flashcard | Stable ID; owning Leaf Deck; content version; hidden/deleted lifecycle |
| `flashcard_translations` | Flashcard | Stable ID; card FK; language/order uniqueness |
| `tags`, `flashcard_tags` | Flashcard | Stable IDs; normalized tag uniqueness; FK cleanup policy |
| `card_audio_refs` | Flashcard | Stable ID; card FK; asset/provider metadata; no player state |
| `learning_progress` | Learning Progress | One row/card; Box 0..8; `due_at`; policy ID/version; revision |
| `study_attempts` | Study Session / Progress handoff | Stable attempt and idempotency keys; evidence/outcome; created UTC |
| `study_sessions` | Study Session | One active-session constraint per selected scope policy; state/revision; snapshot version |
| `study_session_cards` | Study Session | Session/card snapshot; content/progress versions; stable order |
| `study_checkpoints` | Study Session | Stage/round/card position; failed-set and timer state version |
| `study_round_orders` | Study Session | Persisted deterministic seed/order; session/round unique |
| `session_relearn_items` | Study Session | Deduplicated failed card; retry namespace distinct from persistence retry |
| `preferences` | Preferences | Versioned typed key/value or typed columns selected before implementation; invalid fallback |
| `daily_goals`, `goal_day_progress` | Study Goal | Local-date/timezone snapshot; idempotent contribution key |
| `streak_days` | Study Streak | Local date unique; qualified source/version |

## Deck exclusivity

The database transaction derives Deck state from children and direct cards. A
write that would make a Deck contain both fails atomically. SQLite constraints,
triggers, or transaction checks may implement this invariant, but the accepted
behavior is one contract and must have concurrent-writer tests.

## SRS columns

`learning_progress` stores:

- `card_id` unique FK.
- `box` in 0..8.
- `due_at` nullable; null is required for Box 0 and Box 8.
- `policy_id = 'leitner-8-box-v1'` for the baseline policy.
- `policy_version`, `revision`, repetition/lapse counters, and last terminal
  attempt reference.

Eligibility is `due_at <= nowUtc`. Data code persists the result returned by
`lib/domain/learning_progress/srs_8_box_policy.dart`; SQL/DAO/repository code must
not reimplement interval or transition rules.

## Atomic operations

At minimum, one transaction owns each operation:

1. Create Flashcard + initial Box 0 progress + Deck state transition.
2. Start session + card/content/preferences/progress snapshots + initial order.
3. Save attempt evidence + checkpoint before presentation advances.
4. Apply one terminal aggregate outcome + Progress schedule exactly once.
5. Finalize session + contribution events exactly once.
6. Reset Progress/session-derived projections without deleting card content.
7. Import commit and restore apply/rollback.

Every operation declares an idempotency key, expected revision, conflict result,
and crash-recovery behavior in its repository contract.
