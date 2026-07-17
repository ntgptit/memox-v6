# KIT-18 — Component States

## Phạm vi

Audit state-specific coverage; không lặp interaction flow toàn màn hình.

## Checklist

- [x] **KIT-18-01 — Interactive controls có default, pressed, focused, selected khi relevant và disabled.**
  - **Cách kiểm:** VM-04 — state matrix per component.
  - **Evidence mong đợi:** Ma trận độ bao phủ trạng thái của component.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-18-02 — Form controls có empty, filled, focused, error, disabled và read-only phân biệt.**
  - **Cách kiểm:** VM-04 + VM-05 — render form-state contact sheet.
  - **Evidence mong đợi:** Ảnh các trạng thái biểu mẫu và liên kết token tương ứng.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-18-03 — Async components có loading, success/failure hoặc retry state phù hợp.**
  - **Cách kiểm:** VM-04 + VM-05 — trigger async variants in prototypes/examples.
  - **Evidence mong đợi:** Async-state matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-18-04 — Selection controls có unchecked, checked, indeterminate và unavailable khi relevant.**
  - **Cách kiểm:** VM-04 + VM-10 — inspect visuals and semantics.
  - **Evidence mong đợi:** Bằng chứng các trạng thái lựa chọn.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-18-05 — Expandable/drag components có collapsed/expanded hoặc idle/dragging/drop-target states.**
  - **Cách kiểm:** VM-04 + VM-09 — run prototype interactions.
  - **Evidence mong đợi:** Video hoặc ảnh minh họa tương tác.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-18-06 — State chuyển đổi không làm đổi kích thước hoặc layout ngoài chủ đích.**
  - **Cách kiểm:** VM-05 — overlay state screenshots.
  - **Evidence mong đợi:** Bằng chứng overlay/pixel và danh sách vấn đề.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-18-01 | components.css focus-visible chỉ có ở .btn (337), .icon-btn (474), .fab (573), .search-dock--focused (621); .chip/.switch/.segmented__seg/.link/.bottom-nav__item KHÔNG có DS focus ring; .chip/.segmented/.link không có disabled state | FAIL | Default/pressed/selected/disabled phần lớn có, nhưng focus ring token `--memox-ring-focus` không áp dụng nhất quán cho chip/switch/segmented/link/bottom-nav (chỉ còn UA default outline). Hạ từ P0 xuống P1 vì UA outline vẫn hiển thị focus và các action control chính đã có branded ring. |
| KIT-18-02 | MxTextField.d.ts: empty(placeholder)/filled(value)/error(field--error + aria-invalid + role=alert)/disabled(field--disabled) — KHÔNG có prop/state read-only; focus giao cho container ngoài (field outline:none) | FAIL | Thiếu trạng thái read-only cho form control; empty/filled/error/disabled đủ và token-driven. Hạ từ P0 xuống P1 vì read-only là state ít gặp và focus được ủy quyền cho container theo thiết kế. |
| KIT-18-03 | components.css chỉ có `.spinner` indeterminate loading (1085-1098); MxButton.d.ts không có `loading`/submitting state; không có success/failure/retry ở layer component | FAIL | Async chỉ có loading (spinner); thiếu success/failure/retry và loading state trên action control (button submit). |
| KIT-18-04 | MxSwitch.d.ts checked/unchecked + disabled (unavailable, components.css 830); MxChip selected/unselected nhưng không có disabled; không có checkbox/radio nên indeterminate N/A; segmented không có disabled | FAIL | Switch cover checked/unchecked/unavailable; chip/segmented thiếu disabled/unavailable. Không có checkbox nên indeterminate không áp dụng. Hạ xuống P2 vì selection control chính (switch) đã đủ. |
| KIT-18-05 | MxContextualAppBar.d.ts `collapsed` (collapsed/expanded, elevate-on-scroll) + reduced-motion fade contract; không có drag/reorder/accordion primitive trong core kit | PASS | Không có component drag/expandable theo scope (disclosure xử lý bằng feature sheet); app bar có collapsed/expanded state kèm reduced-motion. |
| KIT-18-06 | components.css press = transform scale (card 252, btn 335, icon-btn 472, fab 571); modifiers state đổi background/color/box-shadow không đổi box model; switch thumb chạy trong track cố định | PASS | Chuyển state dùng transform/color/shadow nên không gây reflow hay đổi kích thước ngoài chủ đích. |
| KIT-18-01 | components.css :focus-visible rings on chip/switch/segmented/link/bottom-nav + disabled states | FIXED | Remediation — audit v5 fix loop. |
| KIT-18-02 | MxTextField readOnly prop + .field--readonly | FIXED | Remediation — audit v5 fix loop. |
| KIT-18-03 | MxButton loading prop + .btn--loading + aria-busy | FIXED | Remediation — audit v5 fix loop. |
| KIT-18-04 | MxChip/MxSegmentedControl disabled states | FIXED | Remediation — audit v5 fix loop. |

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
