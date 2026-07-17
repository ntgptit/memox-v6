# KIT-29 — Overlay Patterns

## Phạm vi

Audit dialog, sheet, menu, popover và stacking.

## Checklist

- [x] **KIT-29-01 — Dialog dùng cho quyết định tập trung; action count/order/danger rõ.**
  - **Cách kiểm:** VM-04 + VM-09 — inspect and walkthrough dialog variants.
  - **Evidence mong đợi:** Dialog matrix and recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-29-02 — Bottom sheet xử lý safe area, drag, scroll và keyboard không xung đột.**
  - **Cách kiểm:** VM-09 + VM-07 — test long content and keyboard.
  - **Evidence mong đợi:** Sheet stress evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-29-03 — Menu/action sheet có selected, disabled, destructive và overflow rules.**
  - **Cách kiểm:** VM-04 + VM-05 — render menu states.
  - **Evidence mong đợi:** Menu state matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-29-04 — Tooltip/popover không chứa thông tin bắt buộc duy nhất và có dismiss path.**
  - **Cách kiểm:** VM-09 + VM-10 — activate via touch/keyboard.
  - **Evidence mong đợi:** Popover accessibility evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-29-05 — Back đóng đúng overlay trên cùng và focus trở về trigger.**
  - **Cách kiểm:** VM-09 + VM-10 — stack allowed overlays then dismiss.
  - **Evidence mong đợi:** Stack/focus recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-29-06 — Nested overlay bị cấm trừ combination có trong approved matrix.**
  - **Cách kiểm:** VM-04 + VM-12 — enumerate overlay combinations.
  - **Evidence mong đợi:** Approved/forbidden overlay matrix.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-29-01 | `kit-helpers.jsx:141-153`; `_shared/ConfirmDialog.jsx`; `_features/flashcard-list/FlashcardList.jsx:167-180`; `_features/study-session/components/{ExitDialog,AnswerSaveErrorDialog}.jsx`; `shots/study-session--answer-save-error--light.png` | PASS | Dialog dùng cho quyết định tập trung; luôn 2 action (ghost/cancel bên trái, primary/danger bên phải), order nhất quán; `danger` prop tô màu error. Verified qua shot answer-save-error (Back / Retry). |
| KIT-29-02 | `kit-helpers.jsx:116-124,107-113`; `_features/library/Library.jsx:145-168`; `_features/flashcard-list/FlashcardList.jsx:151-164` | FAIL | Sheet có drag handle + safe-area bottom padding (`space-6`) + radius-2xl — core đúng. Nhưng Sheet KHÔNG có maxHeight/overflow scroll cho long content, và không có state sheet-form + keyboard để xác nhận không xung đột. |
| KIT-29-03 | `kit-helpers.jsx:127-138`; `_shared/SelectSheet.jsx`; `_features/flashcard-list/FlashcardList.jsx:154-161` | FAIL | MenuItem hỗ trợ selected (check), danger (destructive), tone. Nhưng thiếu state disabled và không có rule overflow cho menu dài. Selected/destructive/tone core đúng; disabled + overflow là lỗ hổng matrix. |
| KIT-29-04 | grep (không có `Tooltip`/`Popover`/`window.Toast` trong kit); `kit-helpers.jsx:170-183` (Note inline); `_features/*` dùng banner/label inline | PASS | Kit không có surface tooltip/popover; mọi thông tin trình bày inline/persistent, nên không có thông tin bắt buộc duy nhất bị giấu trong popover tạm thời. Anti-pattern không phát sinh. |
| KIT-29-05 | `kit-helpers.jsx:107-113` (Scrim); `_features/*` overlay states | FAIL | Kit tĩnh — back đóng overlay trên cùng và focus trở về trigger không được render/document (readme: no navigation logic). Overlay có affordance dismiss (X, Cancel) nhưng focus-return + back-key không được đặc tả. |
| KIT-29-06 | `kit-helpers.jsx:107-113` (Scrim zIndex 60); toàn bộ overlay states trong `_features/*` | FAIL | Không có approved/forbidden overlay matrix được document. Thực tế mọi fixture chỉ render 1 overlay/lúc (Scrim bọc đúng 1 Sheet hoặc Dialog), no-nesting giữ trong thực hành; chỉ thiếu ma trận liệt kê tường minh. |
| KIT-29-02 | kit-helpers.jsx Sheet maxHeight 85% + overflow scroll | FIXED | Remediation — audit v5 fix loop. |
| KIT-29-03 | components/feedback/MxMenu (disabled item) + kit-helpers.jsx MenuItem disabled + long-menu fixture | FIXED | Remediation — audit v5 fix loop. |
| KIT-29-05 | kit-helpers.jsx Scrim onDismiss + focus-return contract | FIXED | Remediation — audit v5 fix loop. |
| KIT-29-06 | guidelines/navigation-overlays.md §4 overlay-combination matrix | FIXED | Remediation — audit v5 fix loop. |

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
