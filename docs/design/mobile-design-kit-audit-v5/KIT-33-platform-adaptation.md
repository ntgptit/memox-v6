# KIT-33 — Platform Adaptation

## Phạm vi

Audit shared core vs platform-specific presentation/behavior.

## Checklist

- [x] **KIT-33-01 — Mỗi component/pattern ghi phần shared và phần thích ứng theo platform profile.**
  - **Cách kiểm:** VM-12 — inspect adaptation matrix.
  - **Evidence mong đợi:** Shared/adapted matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-33-02 — Back gesture, modal presentation và navigation không bị ép giống tuyệt đối.**
  - **Cách kiểm:** VM-09 — walkthrough platform prototypes.
  - **Evidence mong đợi:** Platform flow recordings.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-33-03 — System date/time/media/file picker được ưu tiên hoặc custom choice có rationale.**
  - **Cách kiểm:** VM-12 + VM-09 — inspect picker decisions.
  - **Evidence mong đợi:** Picker decision table.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-33-04 — Switch, checkbox, radio, menu và action-sheet adaptation giữ semantic parity.**
  - **Cách kiểm:** VM-04 + VM-10 — compare profiles.
  - **Evidence mong đợi:** Platform component parity matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-33-05 — Typography, icon và touch target khác biệt được ghi mà không đổi meaning.**
  - **Cách kiểm:** VM-05 + VM-10 — side-by-side review.
  - **Evidence mong đợi:** Annotated platform comparison.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-33-06 — Không có public token/component name phụ thuộc tên framework implementation.**
  - **Cách kiểm:** VM-01 — scan names for framework terms.
  - **Evidence mong đợi:** Framework-dependency report bằng 0.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-33-01 | Grep `iOS/Android/Cupertino/Platform.` trong readme/SKILL/components/specs = 0 | FAIL | Kit là một RN visual language thống nhất nhưng không có shared/adapted matrix theo platform profile, và không có scope statement khẳng định "không adaptation theo platform". |
| KIT-33-02 | Không có platform prototype riêng cho iOS/Android; một presentation duy nhất cho back gesture/modal/nav | FAIL | Không có platform flow recordings. Default P3. |
| KIT-33-03 | `_features/reminder/components/TimePickerSheet.d.ts` (custom time picker sheet) + `TimeCol.jsx`; d.ts chỉ mô tả implementation, không nêu rationale chọn custom thay OS-native | FAIL | Picker duy nhất trong scope (reminder time) là custom, thiếu picker decision table/rationale so với system picker. |
| KIT-33-04 | `components/core/MxSwitch`, `MxSegmentedControl`; `kit-helpers.jsx:116` Sheet (action-sheet) — một bộ component chung, không có biến thể theo platform | FAIL | Không có platform component parity matrix; parity đúng trivially do dùng chung nhưng không có evidence dạng matrix. |
| KIT-33-05 | Một type scale (`tokens/typography.css`), Material Symbols cho cả 2 platform, `--memox-touch-min:48px` chung | FAIL | Không có annotated platform comparison. De-escalate P1→P2: type/icon/touch đồng nhất cả hai platform nên không có khác biệt đổi meaning; chỉ thiếu statement mô tả — impact nhỏ. |
| KIT-33-06 | Scan `--memox-*` token names + `Mx*` component names: 0 tên chứa react/native/flutter/ios/android/cupertino; framework terms chỉ nằm trong doc comment (`ConfirmDialog.md` "Flutter target") | PASS | Public token/component names sạch, không phụ thuộc tên framework. |
| KIT-33-01 | SCOPE.md: single visual language, no per-platform adaptation | FIXED | Remediation — audit v5 fix loop. |
| KIT-33-02 | SCOPE.md: platform flow recordings out of scope (single visual language, RN runtime) | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-33-03 | SCOPE.md picker decision table (custom TimePickerSheet rationale) | FIXED | Remediation — audit v5 fix loop. |
| KIT-33-04 | SCOPE.md platform component parity decision table | FIXED | Remediation — audit v5 fix loop. |
| KIT-33-05 | SCOPE.md: typography/icon/touch uniform both platforms | FIXED | Remediation — audit v5 fix loop. |

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
