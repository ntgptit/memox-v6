# KIT-28 — Feedback Patterns

## Phạm vi

Audit lựa chọn đúng feedback surface và severity.

## Checklist

- [x] **KIT-28-01 — Inline feedback chỉ dùng cho target cụ thể và liên kết đúng target.**
  - **Cách kiểm:** VM-05 + VM-10 — inspect field/content errors.
  - **Evidence mong đợi:** Inline feedback examples.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-28-02 — Banner dùng cho section/screen state, có severity và action limit.**
  - **Cách kiểm:** VM-04 + VM-05 — compare banner variants.
  - **Evidence mong đợi:** Banner matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-28-03 — Snackbar/toast không dùng cho critical error cần người dùng xử lý.**
  - **Cách kiểm:** VM-12 — classify feedback catalog by persistence/actionability.
  - **Evidence mong đợi:** Feedback ownership table.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-28-04 — Progress phân biệt determinate/indeterminate và không khóa toàn screen khi không cần.**
  - **Cách kiểm:** VM-09 + VM-05 — run loading patterns.
  - **Evidence mong đợi:** Progress examples.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-28-05 — Cùng sự kiện không phát nhiều feedback trùng lặp ở component và screen.**
  - **Cách kiểm:** VM-09 — trigger outcomes through full pattern.
  - **Evidence mong đợi:** Feedback duplication report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-28-06 — Critical success/failure được announce và không tự biến mất quá nhanh.**
  - **Cách kiểm:** VM-10 + VM-09 — inspect announcement/duration.
  - **Evidence mong đợi:** Accessibility and timing evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-28-01 | `_features/flashcard-editor/components/Field.jsx:36-40`; `shots/flashcard-editor--validation--light.png`; `_features/flashcard-editor/components/DupBanner.jsx` | PASS | Inline error render trực tiếp dưới field liên quan (target-specific), không dùng cho toàn screen. Shot cho thấy "Enter a term." gắn đúng Term, "Enter a meaning." gắn Meaning. |
| KIT-28-02 | `_features/library/Library.jsx:63-74`; `_shared/ActionCallout.jsx`; `kit-helpers.jsx:170-183`; `_features/flashcard-editor/FlashcardEditor.jsx:40-49` | PASS | Banner/callout dùng cho section/screen state; severity qua tone (`*-soft`/`on-*-soft`: error/warning/success/accent); action limit 0-1 (DupBanner 2 lựa chọn cho warning). |
| KIT-28-03 | `_features/study-session/components/AnswerSaveErrorDialog.jsx`; `_features/study-session/components/ResumeErrorState.jsx`; `shots/study-session--answer-save-error--light.png` | PASS | Kit không có surface snackbar/toast. Critical error dùng dialog chặn (answer-save-error có Retry) hoặc EmptyState (resume-error). Toast chỉ nhắc tới cho "keep adding" success không nghiêm trọng. |
| KIT-28-04 | `kit-helpers.jsx:16-35,37-39`; `_features/import/Import.jsx:21-32`; `_features/account-sync/components/SyncBlock.jsx:8-14` | PASS | Determinate = ProgressBar/ProgressHeader kèm value + count (import 62% "77/124", sync 60%, study done/total). Indeterminate = Skeleton loaders. Loading dùng skeleton inline, không khóa full-screen bằng spinner overlay. |
| KIT-28-05 | `_features/flashcard-editor/FlashcardEditor.jsx:137-139`; `shots/flashcard-editor--validation--light.png`; `shots/study-session--answer-save-error--light.png` | PASS | Mỗi outcome render đúng MỘT feedback surface: validation = inline-only (không kèm form banner thừa); submit-success = 1 banner; answer-save-error = 1 dialog. Không thấy trùng lặp component+screen. |
| KIT-28-06 | `_features/study-session/components/AnswerSaveErrorDialog.jsx`; `_features/flashcard-editor/FlashcardEditor.jsx:44,138-139`; `_shared/ConfirmDialog.jsx` | PASS | Critical failure = dialog chặn persistent (không auto-dismiss); banner mang `role="status"` để announce. Không dùng toast tự biến mất cho critical. (role="alert"/assertive là refinement P3, không phải fail.) |

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
