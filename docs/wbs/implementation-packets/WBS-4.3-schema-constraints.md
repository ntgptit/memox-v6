# WBS 4.3 — Schema constraints implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Data / Persistence |
| Depends on | `4.2` — Done (PRs #42/#43/#45) |
| Decision gates | DG-06 (ADR-004) |
| Acceptance | `AC-WBS-4.3-01` |
| Test | `TEST-WBS-4.3-01` |

## Canonical inputs

- `docs/database/schema-v1.md` "Deck exclusivity": a write that would
  make a Deck contain both child decks and direct cards fails
  atomically; constraints, triggers or transaction checks are allowed
  but the behavior is one contract with concurrent-writer coverage.
- `docs/business/deck/README.md` (mixed content is never persisted),
  `organise-deck.md` (block mixed content), `move-deck.md` (cycle
  check on move).
- WBS 4.3: stable IDs, unique sibling names/pairs/attempt keys, FKs and
  deletion policies — the declarative share of these landed inside the
  4.2 DDL; this item owns the cross-table behavioral invariants.

## Scope

- `lib/data/database/tables/constraints.drift` — SQL triggers (SQL-first
  per owner directive) enforcing:
  - **Deck exclusivity** on every mutation path: deck insert/move under
    a card-holding parent, card insert/move into a parent-holding deck,
    and card restore (un-soft-delete) into a deck that gained child
    decks meanwhile. Soft-deleted cards do not count as content.
  - **Acyclic deck tree**: no self-parent on insert; a move may not
    target the deck itself or any descendant (recursive CTE).
  - Violations abort with stable messages `deck-mixed-content` /
    `deck-cycle` for the repository layer to map to typed failures.
- `test/data/database/constraints_schema_test.dart` — contract tests for
  both directions of exclusivity, the soft-delete allowance, the restore
  re-check, move paths, cycle rejection (self, direct child, deep
  descendant) and transactional atomicity (a violating write inside a
  transaction rolls the whole transaction back).

Recorded boundaries:

- **Concurrent writers**: triggers run inside the writing transaction
  under SQLite's single-writer lock, so interleaved writers serialize
  and each conflicting write fails atomically — the tests exercise both
  serialized orders. True multi-isolate contention evidence rides the
  Tier-1 platform smoke (5.7.4/16.1), same as opener execution.
- Repository-level atomic operations (schema-v1 "Atomic operations"
  1–7) are owned by WBS 4.6 repository contracts, not triggers.

## Acceptance and test procedure

`AC-WBS-4.3-01`: no write path can persist a Deck with both child decks
and direct (non-deleted) cards; the deck tree stays acyclic; violations
fail atomically with stable error tags; declarative uniqueness/FK
policies from 4.2 remain intact.

`TEST-WBS-4.3-01`: `constraints_schema_test.dart` in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `4.3` Done; next candidates
  `4.4` (DAO layer, XL — child boundaries by domain) and `4.5`
  (mappers).
