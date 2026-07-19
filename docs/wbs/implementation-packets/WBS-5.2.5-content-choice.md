# WBS 5.2.5 — Empty Deck content choice implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Deck / Presentation |
| Depends on | `5.2.4` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.2.5-01` |
| Test | `TEST-WBS-5.2.5-01` |

## Canonical inputs

- `deck/README.md` §0 + `organise-deck.md`: Empty never locks a
  content type; the first card creates Leaf, the first child creates
  Parent; forbidden transitions are blocked; returning to Empty
  reopens every choice with no stale lock; cancel/failure keeps Empty.

## Scope

- The Empty branch completes its §5 action set: `Add card` (primary),
  `Create nested deck` (secondary, live via the §8 dialog) and the new
  `Import cards` tertiary (ghost; activates with the 8.x
  content-transfer flow — recorded).
- The action sets per state were shipped across 5.2.4 (Leaf: Add card
  only; Parent: Create deck only); this item pins them as a decision
  table with tests.
- `test/presentation/features/deck/content_choice_test.dart` — the
  decision table: Empty shows all three choices; Leaf shows Add card
  only; Parent shows Create deck only; soft-deleting the last card
  returns to Empty and **reopens every choice** (no stale lock); and
  the store backstop rejects a child under a Leaf with
  `deck-mixed-content` even when bypassing the UI.

Recorded boundaries: `Add card` activation belongs to the 5.3
flashcard flow; `Import cards` to 8.x. Both stay visible-but-inactive
so the choice architecture is complete.

## Acceptance and test procedure

`AC-WBS-5.2.5-01`: every deck state renders exactly its allowed
actions; the choice reopens on return-to-Empty; forbidden transitions
are store-blocked with the stable code.

`TEST-WBS-5.2.5-01`: `content_choice_test.dart` in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `5.2.5` Done; `5.2.6` (Deck
  tests/evidence) closes the Deck block next.
