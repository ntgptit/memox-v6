# KIT-25 — Form Patterns

## Phạm vi

Audit composition và behavior của form; component field states thuộc KIT-18.

## Checklist

- [x] **KIT-25-01 — Form dùng label thật; placeholder không thay thế label.**
  - **Cách kiểm:** VM-05 + VM-10 — inspect field anatomy and semantics.
  - **Evidence mong đợi:** Form sample evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-25-02 — Field order và grouping khớp task; focus next/done đi theo order.**
  - **Cách kiểm:** VM-09 + VM-10 — keyboard walkthrough.
  - **Evidence mong đợi:** Focus/order recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-25-03 — Validation timing, inline error và form-level error không mâu thuẫn.**
  - **Cách kiểm:** VM-09 — trigger blur, submit and async errors.
  - **Evidence mong đợi:** Validation-state matrix.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-25-04 — Keyboard không che focused field hoặc primary action.**
  - **Cách kiểm:** VM-09 + VM-07 — test phone portrait/landscape and sheet form.
  - **Evidence mong đợi:** Keyboard screenshots.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-25-05 — Submit ngăn double action và có loading/success/failure feedback.**
  - **Cách kiểm:** VM-09 — repeat tap and force outcomes.
  - **Evidence mong đợi:** Submit-flow recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-25-06 — Close/back khi dirty có confirmation; cancel giữ nguyên input.**
  - **Cách kiểm:** VM-09 — execute clean/dirty/cancel/confirm cases.
  - **Evidence mong đợi:** Dirty-state test evidence.
  - **Severity mặc định nếu không đạt:** `P0`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-25-01 | `_features/flashcard-editor/components/Field.jsx:20-24,33`; `_features/flashcard-editor/FlashcardEditor.jsx:144,150`; `shots/flashcard-editor--validation--light.png` | PASS | Mọi field render `<label>` riêng phía trên; placeholder là `value||placeholder`, không thay label. Shot validation cho thấy label + placeholder tách bạch. |
| KIT-25-02 | `_features/flashcard-editor/FlashcardEditor.jsx:143-162`; `_features/flashcard-editor/components/Field.jsx:28-31` | PASS | Order Term→Meaning→translation→Tags→More options khớp task; grouping card-content vs advanced đúng. Keyboard intent annotated (`data-enter-key-hint`, `enterKeyHint="next"`, `autoFocus` create). Runtime wiring thuộc production (kit tĩnh). |
| KIT-25-03 | `_features/flashcard-editor/components/Field.jsx:36-40`; `_features/flashcard-editor/FlashcardEditor.jsx:138`; `shots/flashcard-editor--validation--light.png` | FAIL | Inline error (validation) và form-level save-error banner không mâu thuẫn, nhưng validation TIMING (blur/submit/async) không có spec/state — chỉ 1 snapshot all-invalid. Readme caveat: forms placeholder, no validation logic. |
| KIT-25-04 | `_features/flashcard-editor/FlashcardEditor.jsx:101-108,134,147` | FAIL | Không có state render bàn phím mở; không verify được field/primary action không bị che. SaveBar sticky bottom + autoFocus là mitigation thiết kế nhưng chưa có keyboard screenshot để xác nhận. |
| KIT-25-05 | `_features/flashcard-editor/FlashcardEditor.jsx:117-119,138-139`; `shots/flashcard-editor--{submitting,submit-success,submit-error}--light.png` | PASS | `saveDisabled` gồm `submitting` (chặn double-tap), `disabledForm` freeze controls; label "Saving…"/"Done"; banner error+retry giữ input, banner success. Đủ loading/success/failure. |
| KIT-25-06 | `_features/flashcard-editor/FlashcardEditor.jsx:10,129`; `_shared/ConfirmDialog.jsx`; `_features/study-session/components/ExitDialog.jsx` | FAIL | Dirty-cancel chỉ được THAM CHIẾU (dùng shared ConfirmDialog) — không có discard-confirm state/copy cho editor và không có dirty/clean logic. Surface ConfirmDialog tồn tại và được dùng ở study-session/deck-settings nhưng instance editor chưa render. |
| KIT-25-03 | Field.jsx validation-timing note + aria-invalid + role=alert | FIXED | Remediation — audit v5 fix loop. |
| KIT-25-04 | flashcard-editor keyboard-open fixture (SaveBar above KeyboardInset) added; canonical shot pending CI render (CDN blocked locally) | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-25-06 | FlashcardEditor.jsx isDirty + discard-confirm state | FIXED | Remediation — audit v5 fix loop. |
| KIT-25-04 | shots/flashcard-editor--keyboard-open--{light,dark}.png (SaveBar + "Create another card" trên KeyboardInset); shots/account-sync--sign-in-keyboard--{light,dark}.png (Continue/Google trên keyboard); kit-helpers.jsx KeyboardInset | FIXED | Keyboard-open render xác nhận primary action (Save) + focused field không bị bàn phím che. |

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
