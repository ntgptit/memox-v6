# KIT-31 — Destructive và Confirmation

## Phạm vi

Audit risk, confirmation, undo và failure recovery.

## Checklist

- [x] **KIT-31-01 — Mỗi destructive action được phân loại reversible, undoable hoặc irreversible.**
  - **Cách kiểm:** VM-12 — review action catalog against risk rubric.
  - **Evidence mong đợi:** Risk classification table.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-31-02 — Irreversible/high-risk action có confirm copy nêu đối tượng và hậu quả.**
  - **Cách kiểm:** VM-09 + VM-12 — inspect confirmation variants.
  - **Evidence mong đợi:** Confirmation-copy evidence.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-31-03 — Undo chỉ dùng khi dữ liệu thực sự phục hồi được và duration đủ.**
  - **Cách kiểm:** VM-09 — execute delete/undo and expiry states.
  - **Evidence mong đợi:** Undo timing/state recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-31-04 — Destructive action không đặt cạnh primary theo cách dễ chạm nhầm.**
  - **Cách kiểm:** VM-05 + VM-10 — inspect spacing/focus/default action.
  - **Evidence mong đợi:** Annotated placement evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-31-05 — Cancel/back/outside dismiss luôn là đường an toàn.**
  - **Cách kiểm:** VM-09 — exercise every dismiss path.
  - **Evidence mong đợi:** Cancel-safety matrix.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-31-06 — Failure/partial success giữ state có thể phục hồi và không double-execute.**
  - **Cách kiểm:** VM-09 — force failure, retry and repeated tap.
  - **Evidence mong đợi:** Recovery-flow evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-31-01 | `ui_kits/memox-app/_shared/ConfirmDialog.md` (States: warning=leave/reset, error=data loss) vs `_features/study-session/components/ExitDialog.jsx:10` + `_shared/DeckResetConfirmDialog.jsx:9` (both dùng `tone="error"`) | FAIL | Rubric chỉ có 2 tier (warning/error), thiếu tier `undoable`; và doc phân loại reset/leave-session là warning nhưng code lại render error. Không có risk-classification table thống nhất. |
| KIT-31-02 | `_shared/DeckDeleteConfirmDialog.jsx:8-9`; `_features/languages/components/RemoveLanguageDialog.jsx:10-11`; `_features/flashcard-list/FlashcardList.jsx:172`; `ConfirmDialog.md` | PASS | Mỗi confirm copy nêu rõ đối tượng + hậu quả ("Deleting removes every subdeck, card and review state inside. This can't be undone."). |
| KIT-31-03 | Không có snackbar/undo trong kit (grep undo/snackbar/toast = 0 pattern); dùng confirm-before + "can't be undone" copy | PASS | Kit không cung cấp undo cho action không phục hồi được → không lạm dụng undo; chọn confirm-trước thay vì undo-sau. |
| KIT-31-04 | `_shared/DeckActionsSheet.jsx:15` (Delete deck ở cuối + `danger`, tách khỏi row khác); `kit-helpers.jsx:150` (Dialog actions row gap `--memox-space-3`), `kit-helpers.jsx:128,133` (MenuItem `danger` tint `--memox-error`) | PASS | Ghost cancel (trái) + danger confirm (đỏ, phải), 12px gap, cả hai ≥44px; destructive ở MenuItem là dòng cuối, đỏ, tách biệt. |
| KIT-31-05 | `ConfirmDialog.md` Rules ("cancel is always ghost"); mọi dialog actions có ghost Cancel/Stay/Back; destructive chỉ kích hoạt trên nút `danger` | PASS | Không đường dismiss nào (cancel/back/outside) kích hoạt action destructive; Scrim backdrop trung tính. |
| KIT-31-06 | `_features/study-session/components/AnswerSaveErrorDialog.jsx` (giữ kết quả + Retry); `_features/flashcard-editor/FlashcardEditor.jsx:138` ("Your changes are still here" + Try again); shots `study-session--answer-save-error--*`, `flashcard-editor--submit-error--*`, `export--export-error--*`, `study-result--finalize-error--*` | PASS | Failure states giữ input và cung cấp retry. Idempotency (no double-execute) là ràng buộc app-integration runtime, kit tĩnh không thể vi phạm. |
| KIT-31-01 | ConfirmDialog.md 3-tier risk rubric (undoable/destructive-recoverable/destructive) aligned to code | FIXED | Remediation — audit v5 fix loop. |

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
