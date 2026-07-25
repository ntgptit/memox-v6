# WBS 5.4.2 — Due/new/relearn query policy implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-25) |
| Owner/domain | Learning / Domain |
| Depends on | `5.4.1` — Done |
| Decision gates | DG-03, DG-04 |
| Acceptance | `AC-WBS-5.4.2-01` |
| Test | `TEST-WBS-5.4.2-01` |

## Canonical inputs

- `docs/business/learning-progress/surface-due-cards.md`:
  - §1 queues separate due / relearn / new; hidden, deleted and
    out-of-scope cards excluded; a Parent aggregates descendant Leaves
    without double-counting; the same card never appears twice; due
    compares an injected `nowUtc`; reading never mutates progress.
  - §2 consumer scopes — Dashboard (whole library) and Study Deck
    (current Leaf/subtree).
  - §4 classification: **New = Box 0 with `dueAt = null`**,
    **Due = Box 1..7 with `dueAt <= nowUtc`**, Box 8 mastered and in no
    queue; zero due must not be faked into due items.
  - §5 Empty deck → zero; Leaf → direct cards; Parent → descendant Leaf
    cards; a card with missing progress is a repair case under the
    `5.4.1` initialise contract.
  - §7 due-at-equal-now is due; timezone never changes which instants
    have passed.
  - §9 acceptance criteria 1–5.
- Schema v1 `learning_progress` box CHECK, and the `5.4.1` guarantee
  that every stored card carries a progress row.

## Scope

- `lib/data/database/queries/learning_progress.drift`:
  - `countDeckQueues` — recursive subtree walk, so a Leaf answers for
    its direct cards, a Parent for its descendants, and an Empty deck
    for zero without a special case. `COUNT(DISTINCT f.id)` states the
    §1 no-duplicate invariant rather than relying on the join shape.
  - `countLibraryQueues` — the same classification across one language
    pair (Dashboard scope).
  - `pageDueProgress`/`countDueProgress` gain the explicit
    `box BETWEEN 1 AND 7` bound so the queue contract is readable where
    the query is, not inferred from a CHECK two files away.
- `lib/data/database/queries/decks.drift` — `watchRootDeckSummaries`
  classification corrected to the same rule. **This closes `int-2`:**
  it read `new` as "no progress row", which no card can satisfy because
  creation commits a Box-0 row in the same transaction, so `new_count`
  was structurally zero and every deck rendered "up to date".
- `lib/domain/learning_progress/study_queue_counts.dart` —
  `StudyQueueCounts` with `hasNoEligibleCards` and `hasNothingDue`, the
  two states §9 requires consumers to tell apart.
- `LearningProgressRepository.countDeckQueues` / `countLibraryQueues`
  plus the Drift implementations.
- `lib/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart`
  — `forDeck` (typed `ValidationFailure` for an unknown deck) and
  `forLibrary`; `loadStudyQueueCountsUseCase` provider.
- `test/domain/usecases/study_queue_counts_usecase_test.dart` and the
  rewritten Library counter test.

**Out of scope** (named so the boundary is explicit):

- **The relearn queue.** §4 defines it as cards a learner picks from a
  *finalized* session's terminal wrongs — session history, not an SRS
  state — so it cannot be derived from progress. It lands with
  `5.6.13`.
- **New-card limits.** §4 assigns them to effective Study policy, which
  needs `8.2` preferences and the `7.1` local-day boundary.
- **Ordering.** §4 also assigns queue priority/order to Study policy;
  this packet returns counts, not sequences.
- **Library subtree display.** `watchRootDeckSummaries` still counts
  direct cards only. Switching that row to a subtree aggregate changes
  what the Library renders, so it belongs to the Library display
  contract and its `MX-VIS-020` parity evidence, not to this query.

## Acceptance and test procedure

`AC-WBS-5.4.2-01`: queue membership is decided by box — New is Box 0,
Due is Box 1..7 reached at or before `nowUtc`, Box 8 is in neither; a
scope answers for its Leaf cards or its descendants' with no card
counted twice; hidden and soft-deleted cards are excluded; an Empty
scope is distinguishable from a scope with nothing due; and every query
is read-only.

`TEST-WBS-5.4.2-01`: `study_queue_counts_usecase_test.dart` in every
gate — fresh card is New not Due; box 1..7 due with a future-dated
control and Box 8 excluded; due-at-equal-now; parent aggregation across
two depths with the mid-level and leaf controls; empty deck zero;
hidden and deleted exclusion; library scope; a read-only assertion over
box/due/revision/updatedAt; and an unknown deck typed. Plus the Library
summary test, rewritten to build its cards through
`CreateFlashcardUseCase` — the previous version inserted a card with no
progress row, a state the app cannot produce, which is exactly what let
`int-2` through.

## Failure and completion

- Success: register evidence recorded, `5.4.2` Done, `int-2` closed;
  next in the block is `5.4.3` (Leitner 8 Box policy), which becomes the
  only writer of the box and due values these queries read.
