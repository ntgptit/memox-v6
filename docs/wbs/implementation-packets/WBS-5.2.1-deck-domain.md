# WBS 5.2.1 — Deck entity and state derivation implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Deck / Domain |
| Depends on | `0.1`, `5.1.1` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.2.1-01` |
| Test | `TEST-WBS-5.2.1-01` |

## Canonical inputs

- `deck/README.md` §0 — the canonical content-state contract: state is
  **derived from current content, never stored as a mode**; mixed
  content is never rendered or persisted; removing the last content
  returns the deck to Empty.
- `create-deck.md` (trimmed duplicate checks), `move-deck.md`
  (cycle + language-pair checks).

## Scope

- `lib/domain/deck/deck_content_state.dart` — `DeckContentCounts`
  (child decks, active cards: soft-deleted excluded, hidden still
  content) + `DeckContentState {empty, parent, leaf}` +
  `deriveDeckContentState`: deterministic derivation implementing the
  §0 decision table; observing mixed content raises
  `DataCorruptionFailure` because every write path that could create it
  is already trigger-rejected.
- `lib/domain/deck/deck_name.dart` — sibling identity =
  trimmed-lowercase (`normalizeDeckName`); `validateDeckName` returns
  the trimmed display form or a typed `required` failure.
- **Pair invariant closed at the store**: the 4.3 trigger set gains
  `deck-pair-mismatch` — a child's `language_pair_id` must equal its
  parent's on insert and on every reparent (gap found while packeting:
  cross-pair nesting was previously possible). `sqlite_error_mapper`
  maps the new tag; the v1 schema snapshot + verifier helpers were
  re-exported (still schema 1, pre-release).
- `DeckRepository.contentCounts(deckId)` port + Drift implementation
  feeding the derivation from live counts.
- `test/domain/deck/deck_domain_test.dart` — the §0 decision table
  (incl. back-to-Empty and mixed→corruption), name
  normalization/validation, live-count derivation incl. soft-delete
  returning Empty, and both pair-mismatch paths (insert + move) with
  the same-pair control case.

Recorded boundary: reactive `watchContentCounts` lands with its first
consumer (the 5.2.4 Library/open-deck screens).

## Acceptance and test procedure

`AC-WBS-5.2.1-01`: Empty/Leaf/Parent derive deterministically from
counts; mixed is typed corruption; cycle, pair and mixed-content
invariants all enforced at the store with stable conflict codes.

`TEST-WBS-5.2.1-01`: `deck_domain_test.dart` in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `5.2.1` Done; `5.2.2` (Create
  Deck transaction) is next.
