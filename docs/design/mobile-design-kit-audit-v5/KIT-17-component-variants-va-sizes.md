# KIT-17 — Component Variants và Sizes

## Phạm vi

Audit purpose, combinations và density của variants.

## Checklist

- [x] **KIT-17-01 — Mỗi variant có use case khác nhau và không chỉ khác màu.**
  - **Cách kiểm:** VM-12 + VM-05 — compare description and visuals.
  - **Evidence mong đợi:** Variant decision table.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-17-02 — Primary, secondary, tertiary, destructive và inverse không trùng semantic.**
  - **Cách kiểm:** VM-04 — compare properties/tokens/usages.
  - **Evidence mong đợi:** Variant semantic matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-17-03 — Size scale hữu hạn; mỗi size có typography, padding, icon và minimum target rõ.**
  - **Cách kiểm:** VM-04 — inspect size properties.
  - **Evidence mong đợi:** Size specification table.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-17-04 — Compact density không làm touch target nhỏ hơn minimum.**
  - **Cách kiểm:** VM-10 — measure hit areas in compact examples.
  - **Evidence mong đợi:** Compact target report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-17-05 — Property combinations hợp lệ được liệt kê; combination vô nghĩa bị loại.**
  - **Cách kiểm:** VM-04 — enumerate component property combinations.
  - **Evidence mong đợi:** Supported-combination matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-17-06 — Future/Deprecated variant không xuất hiện trong Current templates.**
  - **Cách kiểm:** VM-02 + VM-13 — scan template instances by property.
  - **Evidence mong đợi:** Usage report by status.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-17-01 | MxButton.prompt.md (filled primary -> tonal secondary -> outline -> ghost; contrast = white pill ON colored card); MxCard.d.ts variant (elevated/flat/muted/primary/primary-soft = surface role); components.css per-variant box-shadow/border | PASS | Variant phân theo emphasis/surface role, không chỉ khác màu. |
| KIT-17-02 | MxButton.d.ts variant primary/secondary/outline/ghost/contrast + `danger` (destructive) + contrast (inverse-on-color); components.css .btn.primary/.secondary/.outline/.ghost/.contrast (357-402) | PASS | Primary/secondary/tertiary(outline)/destructive(danger)/inverse(contrast) semantic phân biệt. |
| KIT-17-03 | components.css btn--sm/lg (347-356: min-height size-sm/md, padding, font); component.css avatar sm/md/lg, icon-btn-sm, card pad; icon font-size theo size | PASS | Size scale hữu hạn; mỗi size khai báo typography, padding, icon size và min target qua token. |
| KIT-17-04 | components.css hit-area ::after (988-1013): chip34/switch32/btn--sm/icon-btn--sm36/segmented40/section-action mở rộng lên 48 | PASS | Compact control giữ hit area >=48 qua overlay ::after; visual nhỏ nhưng target không dưới minimum. |
| KIT-17-05 | .d.ts prop union (giới hạn value hợp lệ); .prompt.md ví dụ; không có supported/excluded-combination matrix | FAIL | TS union chặn value sai nhưng combo vô nghĩa (vd danger+contrast, block cho icon-only) chưa được liệt kê là loại trừ. Hạ xuống P2 vì tác động chức năng thấp, chỉ thiếu artifact matrix. |
| KIT-17-06 | Grep `deprecated\|experimental\|future` trong .d.ts/_ds_manifest.json = 0; readme.md:13 "legacy" chỉ nói giá trị màu Tokyo đã migrate, không phải variant | PASS | Không có Future/Deprecated variant; mọi variant đều là Current. |
| KIT-17-05 | guidelines/component-constraints-matrix.md §2 combination matrix | FIXED | Remediation — audit v5 fix loop. |

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
