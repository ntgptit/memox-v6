# Manage Card tags

- Owner: **Flashcard**
- Status: **Canonical**

Tags are reusable labels attached to Flashcards for organization and search. A tag does not own
learning content, scheduling, Deck membership or Study eligibility.

## Invariants

| ID | Rule |
| --- | --- |
| TAG-001 | A label is Unicode NFC and outer-trimmed for validation; the user-visible spelling is preserved. |
| TAG-002 | An empty normalized label is invalid. |
| TAG-003 | Tag uniqueness is app-local by Unicode case-folded normalized label. |
| TAG-004 | Attaching an already attached tag is idempotent. |
| TAG-005 | Removing a tag association never deletes the Flashcard or its Learning Progress. |
| TAG-006 | Deleting an unused tag and updating Card associations are transactional. |

## Flow

1. Open Card Detail or Editor and request tag management.
2. Search existing tags by normalized label.
3. Select existing tags or enter a new label.
4. Validate TAG-001..TAG-003; duplicate creation resolves to the existing tag.
5. Save the association delta in one transaction.
6. Refresh Card Detail, list filters and search projections after commit.

Cancel or persistence failure leaves both associations and draft selections unchanged. Concurrent
creation of the same normalized label resolves through the unique constraint and retries the
association with the existing tag ID.

## Acceptance and tests

- Composed/decomposed Vietnamese and case variants resolve deterministically without changing the
  display label of an existing tag.
- Duplicate attach/retry creates one association.
- Removing/deleting tags cannot mutate Card content, Deck membership or Progress.
- Repository tests cover transaction rollback and concurrent same-label creation.
- Widget/E2E tests cover empty, search/no-results, selected, validation, saving and failure states.
