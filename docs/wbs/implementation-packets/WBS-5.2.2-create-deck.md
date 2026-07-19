# WBS 5.2.2 — Create Deck transaction implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Deck / Domain |
| Depends on | `5.2.1` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.2.2-01` |
| Test | `TEST-WBS-5.2.2-01` |

## Canonical inputs

- `create-deck.md`: root and nested create through one dialog; trimmed
  duplicate checks; retry after unknown outcome must not double-create;
  a new deck never receives automatic content.
- The 5.2.1 name normalization and store invariants.

## Scope

- `lib/domain/usecases/deck/create_deck_usecase.dart` — one atomic
  insert with **no automatic content** (a new deck is always Empty,
  content type unlocked):
  - typed validation (`deckName required`, unknown pair/parent);
  - store-enforced conflicts surface with their stable codes
    (`duplicate` sibling names per parent, `deck-mixed-content` under a
    card-holding parent, `deck-pair-mismatch` across pairs);
  - **retry idempotency** via [retryDeckId]: the caller keeps the id it
    generated for the first attempt; a retry that finds it stored
    returns the stored deck unchanged — never a second insert.
- `createDeckUseCase` provider joins `lib/app/di/usecase_providers.dart`.
- `test/domain/usecases/create_deck_usecase_test.dart` — root create
  proving Empty derivation (no auto content), nested create flipping
  the parent to Parent state, per-parent sibling collision with the
  cross-parent control, idempotent retry (one row), typed unknown
  pair/parent validation, and the mixed-content conflict path.

## Acceptance and test procedure

`AC-WBS-5.2.2-01`: root/nested create commits atomically with no
automatic content; sibling uniqueness is normalized and typed; a kept
retry id makes retries idempotent; every failure is a taxonomy type
with a stable code.

`TEST-WBS-5.2.2-01`: `create_deck_usecase_test.dart` in every gate.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `5.2.2` Done; next in the block
  is `5.2.3` (first-run landing + two-step setup, XL — child
  boundaries in its packet).
