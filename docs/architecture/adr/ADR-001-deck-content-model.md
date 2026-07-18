# ADR-001 — Exclusive Deck content model

- Status: **Accepted**
- Owner: Product
- Accepted: 2026-07-18
- Decision gate: DG-01

## Context

Business rules model Empty, Leaf, and Parent Deck states, while the design kit
has also used language that permits cards and child Decks together.

## Decision

A Deck derives exactly one state:

- Empty: no direct cards and no child Decks.
- Leaf: one or more direct cards and no child Decks.
- Parent: one or more child Decks and no direct cards.

“Nested deck” is a Deck with `parentId`; it is not a separate aggregate. A
transaction that would create mixed content fails without partial mutation.

## Consequences

- Add-card and create-child eligibility are mutually exclusive.
- Move/import operations revalidate the target in the same transaction.
- Design prose/fixtures that show mixed content require Product/Design
  reconciliation before implementation.

## Verification

Decision tables and tests cover Empty→Leaf, Empty→Parent, rejected mixed
transitions, concurrent writers, move/import, deletion back to Empty, and cycle
prevention. Database constraints are defined in
[`../../database/schema-v1.md`](../../database/schema-v1.md).
