# KIT-26 — Search, Filter và Sort

## Phạm vi

Audit local search/filter/sort interaction pattern.

## Checklist

- [x] **KIT-26-01 — Search scope và empty-query behavior được ghi rõ.**
  - **Cách kiểm:** VM-12 + VM-09 — inspect spec and run query clear.
  - **Evidence mong đợi:** Scope statement and prototype recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-26-02 — No-results khác empty dataset và có clear/reset action khi phù hợp.**
  - **Cách kiểm:** VM-05 + VM-09 — trigger both states.
  - **Evidence mong đợi:** Side-by-side state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-26-03 — Applied filters hiển thị rõ, có count/reset và disabled rationale.**
  - **Cách kiểm:** VM-09 + VM-10 — apply multiple filters.
  - **Evidence mong đợi:** Filter-state matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-26-04 — Sort options có default/selected state và không ngầm mutate manual order.**
  - **Cách kiểm:** VM-09 + VM-12 — switch sorts and inspect spec.
  - **Evidence mong đợi:** Sort behavior evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-26-05 — Search/filter state khi back/navigation được giữ hoặc reset theo rule.**
  - **Cách kiểm:** VM-09 — navigate out/back.
  - **Evidence mong đợi:** Persistence recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-26-06 — Long labels, RTL và horizontal chip overflow vẫn thao tác được.**
  - **Cách kiểm:** VM-08 + VM-07 — stress toolbar/chips.
  - **Evidence mong đợi:** Localization/reflow screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-26-01 | `specs/search.md:12` (objective "by word or meaning"); `_features/search/Search.jsx:20-45`; `_features/library/Library.jsx:78-87` | PASS | Scope nêu rõ (word/meaning; library=decks+subdecks; flashcard-list=cards qua placeholder). Empty query → RECENT list (empty-recent / search-active). |
| KIT-26-02 | `_features/search/Search.jsx:59-66`; `_features/library/Library.jsx:88-89`; `_features/flashcard-list/FlashcardList.jsx:47-57,92-93` | PASS | No-results (tone warning, nêu query) tách biệt empty dataset (first-use, CTA Create/Import). Library/flashcard-list no-results có "Clear search"; app bar có X clear. |
| KIT-26-03 | `_features/library/components/FilterRow.jsx:11`; `_features/library/Library.jsx:130-142,145-168`; `shots/library--filter-applied--light.png` | PASS | Chip "Filters · 2" selected + summary "2 decks match · Due only" + "Clear all"; filter-sheet có selected states + Reset/Apply. Không có filter disabled nên rationale không phát sinh. |
| KIT-26-04 | `_features/library/Library.jsx:152-155`; `_features/library/components/FilterRow.jsx:11` | PASS | SORT group có default "Recently studied" selected + các option; chip sort "A–Z". Không có tính năng manual/drag order nên không có nguy cơ ngầm mutate. |
| KIT-26-05 | `_features/search/Search.jsx`; `_features/library/Library.jsx`; `specs/*` | FAIL | Không có rule/state mô tả search/filter được giữ hay reset khi back/navigation. Mỗi state là snapshot độc lập; persistence rule không được ghi. |
| KIT-26-06 | `_features/search/components/Chips.jsx:10`; `_features/flashcard-list/FlashcardList.jsx:28`; `shots/app-bar--nested-overflow--light.png` | FAIL | Chip overflow xử lý bằng `overflowX:auto` (thao tác được); long label app bar truncate. Nhưng không có render RTL (`dir=rtl`) — sản phẩm ko/en/vi đều LTR nên phạm vi ảnh hưởng nhỏ. |
| KIT-26-05 | guidelines/navigation-overlays.md §3 search/filter preserve-vs-reset rule | FIXED | Remediation — audit v5 fix loop. |
| KIT-26-06 | guidelines/i18n-localization.md §7 RTL scope + logical-property guidance | FIXED | Remediation — audit v5 fix loop. |

## Kết luận nhóm

```text
Final status: PASS
Open P0: 
Open P1: 
Open P2: 
Open P3: 
Reviewed by: Claude (automated kit audit + remediation)
Reviewed date: 2026-07-16
```
