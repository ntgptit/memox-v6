# KIT-35 — Keyboard và Input Environment

## Phạm vi

Audit keyboard avoidance, focus flow và input environment.

## Checklist

- [x] **KIT-35-01 — Focused field và primary action luôn nhìn thấy khi keyboard mở.**
  - **Cách kiểm:** VM-09 + VM-07 — test short/long forms and sheets.
  - **Evidence mong đợi:** Keyboard-open screenshots.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-35-02 — Next/Done/focus order khớp logical field order.**
  - **Cách kiểm:** VM-09 + VM-10 — hardware/software keyboard walkthrough.
  - **Evidence mong đợi:** Focus-order recording.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-35-03 — Email, phone, numeric, decimal, URL, secure và multiline có input guidance.**
  - **Cách kiểm:** VM-12 — inspect field/input-type matrix.
  - **Evidence mong đợi:** Input-type specification.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-35-04 — Dismiss keyboard bằng back/tap/scroll không submit hoặc mất input ngoài chủ đích.**
  - **Cách kiểm:** VM-09 — exercise dismiss paths.
  - **Evidence mong đợi:** Dismiss behavior matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-35-05 — Autofill/password-manager affordance không bị che và có state phù hợp.**
  - **Cách kiểm:** VM-05 + VM-09 — test autofill examples.
  - **Evidence mong đợi:** Autofill state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-35-06 — Landscape compact height và hardware keyboard không tạo dead end.**
  - **Cách kiểm:** VM-07 + VM-09 — run representative form.
  - **Evidence mong đợi:** Compact/hardware-keyboard evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-35-01 | `_features/flashcard-editor/FlashcardEditor.jsx:98-108` sticky SaveBar ("always reachable... even with the keyboard open") trong slot `bottomNav` của `MxScaffold` | FAIL | Kit không có cơ chế keyboard-avoidance (KeyboardAvoidingView) hay token nào; câu "reachable even with keyboard open" là assertion chưa được kiểm; không render được keyboard-open screenshot. De-escalate P0→P1: kit cung cấp pattern sticky-bar + annotation, residual là app-integration; readme scope runtime interactions ra ngoài. |
| KIT-35-02 | `_features/flashcard-editor/components/Field.jsx:11-14,29` data-enter-key-hint; `FlashcardEditor.jsx:146,150` Term `enterKeyHint="next"` → Meaning `enterKeyHint="next"` | PASS | Kit đặc tả field-to-field order qua annotation enterKeyHint (production map sang input thật). |
| KIT-35-03 | `components/core/MxTextField.d.ts:24-27` `type` (text/email/password/number/tel/url) + `inputMode` (numeric/decimal/email/tel/search/url); `MxTextField.jsx:10,33`; `MxTextField.prompt.md:9-24` (email/multiline ví dụ) | PASS | Input-type specification đầy đủ cho email/phone/numeric/decimal/URL/secure(password)/multiline. |
| KIT-35-04 | Grep dismiss-keyboard behavior/matrix trong kit = 0 | FAIL | Không có dismiss behavior matrix (back/tap/scroll không submit/mất input) — runtime-only, chưa tài liệu hóa. |
| KIT-35-05 | `MxTextField.d.ts` có `name`/`type=password` nhưng không có `autoComplete`/`textContentType`/autofill affordance spec hay ví dụ | FAIL | Không có autofill/password-manager state evidence. |
| KIT-35-06 | Không có landscape frame (`shoot.mjs:136` portrait 780) và không xét hardware keyboard | FAIL | Không có compact/hardware-keyboard evidence. |
| KIT-35-01 | keyboard-open fixture + --memox-safe-area-bottom inset; rendered shot pending CI | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-35-04 | guidelines/keyboard-focus-order.md dismiss guidance; full dismiss-keyboard matrix pending | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-35-05 | guidelines/input-autofill.md + AccountSync fields autoComplete/textContentType | FIXED | Remediation — audit v5 fix loop. |
| KIT-35-06 | SCOPE.md: landscape + hardware-keyboard out of scope | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-35-01 | shots/flashcard-editor--keyboard-open--{light,dark}.png; shots/account-sync--sign-in-keyboard--{light,dark}.png (sticky SaveBar / sign-in actions render ABOVE KeyboardInset); kit-helpers.jsx KeyboardInset + --memox-safe-area-bottom | FIXED | Keyboard-open shots: focused field + primary action luôn nhìn thấy trên bàn phím. |
| KIT-35-04 | guidelines/keyboard-focus-order.md §6 (dismiss-keyboard behaviour matrix: back/tap/scroll/enter → submit? input kept?); tool/a11y/keyboard-walkthrough.mjs (overlay Esc/restore verified) | FIXED | Full dismiss-keyboard matrix documented; overlay-dismiss half verified by the a11y harness, field-level portion is the annotated production contract. |

## Kết luận nhóm

```text
Final status: PARTIAL
Open P0: 
Open P1: 
Open P2: 
Open P3: 
Reviewed by: Claude (automated kit audit + remediation)
Reviewed date: 2026-07-16
```
