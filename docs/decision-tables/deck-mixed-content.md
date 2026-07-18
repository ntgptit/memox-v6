# DECK-MIX-v1 — Exclusive Deck content decision table

Source decision: [ADR-001](../architecture/adr/ADR-001-deck-content-model.md) (DG-01). Deck state là derived — Empty/Leaf/Parent — không phải persisted mode. Mọi row chạy trong đúng một transaction; failure không để partial mutation. Database constraints tại [`../database/schema-v1.md`](../database/schema-v1.md).

| ID | Given | When | Then |
| --- | --- | --- | --- |
| DECKMIX-001 | Empty Deck | Add first direct card | Card created; Deck derives Leaf |
| DECKMIX-002 | Empty Deck | Create first child Deck | Child created; Deck derives Parent |
| DECKMIX-003 | Leaf Deck | Add direct card | Card created; Deck remains Leaf |
| DECKMIX-004 | Leaf Deck | Create child Deck | Typed mixed-content rejection; no child, no state change |
| DECKMIX-005 | Parent Deck | Add direct card | Typed mixed-content rejection; no card, no state change |
| DECKMIX-006 | Parent Deck | Create child Deck | Child created; Deck remains Parent |
| DECKMIX-007 | Empty Deck; two concurrent writers add card and child | Both commit attempts | Exactly one succeeds; loser gets typed mixed-content/conflict rejection; final state Leaf or Parent, never both |
| DECKMIX-008 | Leaf target | Move/import cards into target | Cards attached; target remains Leaf |
| DECKMIX-009 | Parent target | Move/import cards into target | Typed mixed-content rejection; source unchanged |
| DECKMIX-010 | Empty target | Move/import cards into target | Cards attached; target derives Leaf |
| DECKMIX-011 | Target became Parent after selection (stale target) | Commit move/import of cards | Revalidation in same transaction rejects; user re-picks target |
| DECKMIX-012 | Leaf Deck | Delete/move away last direct card | Deck derives Empty; both add-card and create-child eligible again |
| DECKMIX-013 | Parent Deck | Delete/move away last child Deck | Deck derives Empty; both add-card and create-child eligible again |
| DECKMIX-014 | Deck A ancestor of Deck B | Reparent A under B | Cycle rejection; hierarchy unchanged |
| DECKMIX-015 | Deck A | Reparent A under A | Self-parent rejection; hierarchy unchanged |

Version note: thay đổi semantics của một row yêu cầu `DECK-MIX-v2` với mapping rõ ràng; không đổi nghĩa âm thầm dưới cùng ID.
