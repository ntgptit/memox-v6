# Search business flows

Search là read capability trên Deck và Flashcard với query, filters, recent searches và index lifecycle. Object nguồn vẫn sở hữu content/eligibility.

## Invariants

- Search không mutate Deck/Card.
- Result identity/path luôn đủ để mở đúng object.
- Deleted/hidden content tuân visibility/filter policy và không giữ stale actionable result.
- Query blank khác no-results.
- Ranking deterministic với cùng query/index/formula version.
- Recent-search persistence không chứa content nhạy cảm ngoài policy đã chốt.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [search-library-content.md](./search-library-content.md) | Query Deck/Card theo word/meaning/name | Đã có |
| [filter-search-results.md](./filter-search-results.md) | Filter theo object/language/deck/visibility | Đã có |
| [open-search-result.md](./open-search-result.md) | Resolve current object/path và return preservation | Đã có |
| [manage-recent-searches.md](./manage-recent-searches.md) | Add, dedupe, clear và privacy behavior | Đã có |
| [update-search-index.md](./update-search-index.md) | Create/edit/move/delete invalidation | Đã có |
| [recover-search-failure.md](./recover-search-failure.md) | Loading/error/stale index/rebuild | Đã có |

## Cross-object contracts

- Deck/Flashcard cung cấp searchable fields và stable ids; Search không redefine validation.
- Open Deck dùng `deck/open-deck.md`; Open/Edit Card dùng Flashcard contracts.
- Target-picker search áp eligibility của owning Move/Add flow, không của Search.
- Statistics/Progress content không được index như Card text nếu chưa có explicit scope.

## Canonical state coverage

- Empty/recent; typing/loading/results/filtered/no-results/error.
- Deck/Card mixed results; duplicate names with paths; hidden/deleted/stale.
- Long multilingual query/result, keyboard, large font, narrow, light/dark.
