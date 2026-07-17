# KIT-16 — Component Anatomy

## Phạm vi

Audit slots, hierarchy và constraints bên trong component.

## Checklist

- [x] **KIT-16-01 — Mỗi component xác định required/optional slots bằng vocabulary chuẩn.**
  - **Cách kiểm:** VM-04 + VM-12 — inspect component properties và anatomy docs.
  - **Evidence mong đợi:** Slot matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-16-02 — Optional slot rỗng không để lại spacing hoặc alignment artifact.**
  - **Cách kiểm:** VM-04 + VM-05 — hiển thị tất cả tổ hợp bật/tắt slot hợp lệ.
  - **Evidence mong đợi:** Combination screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-16-03 — Primary, supporting, metadata và action content có hierarchy cố định.**
  - **Cách kiểm:** VM-05 — populate realistic mixed content.
  - **Evidence mong đợi:** Annotated anatomy evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-16-04 — Text wrapping, min/max size và action count constraints được định nghĩa.**
  - **Cách kiểm:** VM-07 + VM-08 — stress long text and narrow width.
  - **Evidence mong đợi:** Constraint matrix and overflow report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-16-05 — Size/variant changes không đổi semantic order của slots.**
  - **Cách kiểm:** VM-04 — compare anatomy across variants/sizes.
  - **Evidence mong đợi:** Anatomy diff report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-16-06 — Không cho phép interactive target lồng trong interactive target trái rule.**
  - **Cách kiểm:** VM-10 + VM-04 — inspect nested combinations.
  - **Evidence mong đợi:** Invalid-combination list and allowed alternatives.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-16-01 | .d.ts optional markers: MxContextualAppBar.d.ts (leading/title/actions/notification/avatar), MxSectionHeader.d.ts (title/caption/action), MxButton.d.ts (icon/trailingIcon), MxCard.d.ts (children); .prompt.md anatomy docs | PASS | Required/optional slot khai báo qua `?` trong prop union và vocabulary chuẩn (leading/trailing/title/caption/action/icon/label). |
| KIT-16-02 | MxButton.jsx (icon/children/trailingIcon render có điều kiện), MxSectionHeader.jsx (caption/action conditional), MxContextualAppBar.d.ts ("Omit when count is 0") | PASS | Slot rỗng không render node; flex gap tự thu lại nên không để lại spacing/alignment artifact. |
| KIT-16-03 | components.css .section-head__title/.section-head__caption/.section-head__action (1015 vùng); MxContextualAppBar reading order contract (.d.ts); typography roles token | PASS | Primary/supporting/action gắn class và typography role cố định nên hierarchy ổn định. |
| KIT-16-04 | MxContextualAppBar.d.ts (title single-line truncates; actions "MAX 2 directly visible, 3rd+ overflow"); components.css btn/chip `white-space: nowrap` (332, 712) | FAIL | Chỉ MxContextualAppBar định nghĩa rõ constraint (truncate + action count); chưa có constraint matrix toàn kit cho text-wrapping/min-max/action-count của card/list. Hạ xuống P2 vì component dễ overflow nhất (app bar) đã được ràng buộc. |
| KIT-16-05 | components.css size modifiers chỉ đổi dimension/padding/font (btn--sm/lg 347-356, card--pad-*, avatar--sm/lg 900-910); MxButton.jsx/MxCard.jsx render slot order bất biến theo variant | PASS | Variant/size không đổi thứ tự semantic của slot. |
| KIT-16-06 | MxCard.jsx: khi actionable đặt `role="button"` + tabIndex; không có tài liệu invalid-combination cho nested interactive | FAIL | Kit chưa có invalid-combination list; MxCard interactive có thể lồng interactive child mà không bị guard. Hạ xuống P2 vì không component core nào tự lồng interactive; đây là doc/usage-guard gap. |
| KIT-16-04 | guidelines/component-constraints-matrix.md §1 | FIXED | Remediation — audit v5 fix loop. |
| KIT-16-06 | guidelines/component-constraints-matrix.md §3 nested-interactive rule | FIXED | Remediation — audit v5 fix loop. |

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
