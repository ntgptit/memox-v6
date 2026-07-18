# flashcard-list — Flashcard List — screen spec

> Rebaselined 2026-07-18 from `../_features/flashcard-list/FlashcardList.jsx` and the ratified
> exclusive Deck-kind decision. The historical generator cited by older copies is not present;
> this spec is manually maintained until replacement tooling is committed.

## Objective (contract §1)

Browse, filter and manage the cards in a final deck.

Primary CTA: **Add card**

## Archetype (contract §2)

List

## Composition map (contract §3)

Top → bottom: **nested MxContextualAppBar** → primary content → primary action (Add card).
Exact layout order is owned by the source (`../_features/flashcard-list/FlashcardList.jsx`) and the reference PNGs — read those for pixel
composition; the component map below is the authoritative set of pieces in play.

## Component map (contract §3) — auto-derived from source

`MxButton`, `MxCard`, `MxChip`, `MxContextualAppBar`, `MxFab`, `MxIconButton`, `MxLink`, `MxList`, `MxScaffold`, `MxSearchDock`, `window.ActionCallout`, `window.Breadcrumb`, `window.EmptyDeck`, `window.Note`, `window.StatusCardRow`

## Active state matrix (contract §6) — 16 states

| # | state |
| --- | --- |
| 1 | `loaded` |
| 2 | `dense` |
| 3 | `minimum-data` |
| 4 | `long-text` |
| 5 | `empty` |
| 6 | `search` |
| 7 | `no-results` |
| 8 | `filter-applied` |
| 9 | `selection` |
| 10 | `add-sheet` |
| 11 | `card-actions` |
| 12 | `delete-confirm` |
| 13 | `loading` |
| 14 | `offline` |
| 15 | `error` |
| 16 | `not-found` |

`convert-dialog`, `convert-submitting` and `convert-failure` are deprecated compatibility
states. They are not routable and must fail closed without changing Deck kind or moving cards.
Their old PNGs are historical evidence only.

## Handoff notes

Spacing scale `{4,8,12,16,24,32,48}`; screen padding 16; tokens only (no raw hex / off-scale).
Exactly one primary objective; touch targets ≥ 48×48. Medium/expanded/landscape behaviour follows
`../../../guidelines/flutter-adaptive-layout.md` and requires new Tier-1 evidence.
