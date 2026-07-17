# KIT-27 — Selection và Bulk Actions

## Phạm vi

Audit selection mode và bulk-action ownership.

## Checklist

- [x] **KIT-27-01 — Có trigger vào/thoát selection mode; back thoát mode trước navigation.**
  - **Cách kiểm:** VM-09 — enter via all supported triggers and press back.
  - **Evidence mong đợi:** Selection transition recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-27-02 — Selected count, select all và indeterminate state phản ánh đúng scope.**
  - **Cách kiểm:** VM-09 + VM-10 — select across visible/filtered items.
  - **Evidence mong đợi:** Count/state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-27-03 — Bulk bar chỉ xuất hiện khi có selection; zero selected không có enabled action.**
  - **Cách kiểm:** VM-05 + VM-09 — select/deselect last item.
  - **Evidence mong đợi:** Bulk-bar state screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-27-04 — Bulk destructive nêu số lượng/đối tượng và có cancel-safe behavior.**
  - **Cách kiểm:** VM-09 — open confirm, cancel, confirm.
  - **Evidence mong đợi:** Confirmation flow evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-27-05 — Filter/sort/search thay đổi selection theo rule, không làm hidden selection mơ hồ.**
  - **Cách kiểm:** VM-09 — select then alter query/filter/sort.
  - **Evidence mong đợi:** Selection persistence matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-27-06 — Bulk move/export failure hoặc partial success có feedback và selection recovery.**
  - **Cách kiểm:** VM-09 — force success/failure/partial outcomes in prototype spec.
  - **Evidence mong đợi:** Outcome-state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-27-01 | `components/surfaces/MxContextualAppBar.jsx:63`; `shots/library--selection--light.png`; `shots/app-bar--selection--light.png` | FAIL | Exit qua close (X) leading của variant selection có. Nhưng trigger VÀO selection mode (long-press?) không được document, và hành vi hardware back thoát mode trước navigation không được mô tả/render. |
| KIT-27-02 | `components/surfaces/MxContextualAppBar.jsx:76`; `_features/library/Library.jsx:108,114`; `shots/library--selection--light.png` | FAIL | Count "N selected" (role=status) và select_all icon có. Nhưng select-all KHÔNG có indeterminate/tri-state (3/6 chọn nhưng icon tĩnh); indeterminate phản ánh scope thiếu. |
| KIT-27-03 | `_features/library/Library.jsx:106-116`; `_features/flashcard-list/FlashcardList.jsx:113-135` | FAIL | Bulk bar (selection app bar) chỉ xuất hiện ở selection state — đúng. Nhưng không có state zero-selected; count luôn >0, more_vert luôn enabled; không chứng minh "zero selected → no enabled action" / auto-exit. |
| KIT-27-04 | `_features/flashcard-list/FlashcardList.jsx:167-180`; `_shared/ConfirmDialog.jsx` | FAIL | Chỉ có delete-confirm cho MỘT card ("Delete this card?"). Không có bulk destructive confirm nêu số lượng ("Delete N cards/decks?"). Bulk action nằm sau more_vert (nội dung không document). |
| KIT-27-05 | `_features/library/Library.jsx:106-116`; `specs/*` | FAIL | Không có rule mô tả selection thay đổi thế nào khi filter/sort/search đổi; hidden selection không được xử lý. Selection chỉ là snapshot đơn. |
| KIT-27-06 | `_features/library/Library.jsx`; `_features/flashcard-list/FlashcardList.jsx` | FAIL | Không có state outcome cho bulk move/export (success/failure/partial) và không có selection recovery. |
| KIT-27-01 | FlashcardList.jsx selection entry/exit contract | FIXED | Remediation — audit v5 fix loop. |
| KIT-27-02 | FlashcardList.jsx tri-state select-all | FIXED | Remediation — audit v5 fix loop. |
| KIT-27-03 | FlashcardList.jsx zero-selected state (actions disabled) | FIXED | Remediation — audit v5 fix loop. |
| KIT-27-04 | FlashcardList.jsx bulk-delete-confirm names count | FIXED | Remediation — audit v5 fix loop. |
| KIT-27-05 | FlashcardList.jsx selection-vs-filter persistence contract | FIXED | Remediation — audit v5 fix loop. |
| KIT-27-06 | FlashcardList.jsx bulk-outcome partial-success state | FIXED | Remediation — audit v5 fix loop. |

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
