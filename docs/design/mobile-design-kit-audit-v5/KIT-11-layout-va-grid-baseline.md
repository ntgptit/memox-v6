# KIT-11 — Layout và Grid Baseline

## Phạm vi

Chỉ audit baseline grid/keyline trên phone; tablet/large-screen/breakpoint thuộc KIT-32.

## Checklist

- [x] **KIT-11-01 — Phone baseline có viewport range, screen margin, gutter và column rule rõ.**
  - **Cách kiểm:** VM-12 + VM-07 — đọc spec rồi resize trong range phone.
  - **Evidence mong đợi:** Grid specification và screenshots min/default/max phone width.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-11-02 — Primary content, headers và actions bám cùng keyline semantic.**
  - **Cách kiểm:** VM-05 — overlay guides trên representative screens.
  - **Evidence mong đợi:** Annotated keyline evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-11-03 — Full-bleed content có điều kiện và không phá content safe margin.**
  - **Cách kiểm:** VM-05 + VM-07 — test media/banner full-bleed trên phone widths.
  - **Evidence mong đợi:** Screenshots và list allowed full-bleed patterns.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-11-04 — Section structure giữ order header → content → actions khi section ẩn/hiện.**
  - **Cách kiểm:** VM-07 — toggle optional sections và inspect spacing/order.
  - **Evidence mong đợi:** State comparison evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-11-05 — Reading content và form có max readable width ngay trong phone landscape khi cần.**
  - **Cách kiểm:** VM-07 — test compact landscape width/height.
  - **Evidence mong đợi:** Measured content-width evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-11-06 — Layout chính không dựa tọa độ tuyệt đối hoặc frame cố định theo một thiết bị.**
  - **Cách kiểm:** VM-02 + VM-07 — inspect constraints và resize.
  - **Evidence mong đợi:** Constraint inspection report; overflow count bằng 0.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-11-01 | tokens/spacing.css:22; components.css:654 (narrow-frame); shots 390×780 (single width) | FAIL | Có gutter keyline 16 + layout flex fluid + xử lý frame hẹp, nhưng không có grid spec ghi viewport range (min/default/max phone) và shot chỉ một width; thiếu evidence reflow đa width. |
| KIT-11-02 | components.css:43,88 | PASS | Keyline 16 đồng nhất — app__body padding gutter, cappbar padding 0 gutter (“same horizontal grid as content”); header+content+actions cùng canh. |
| KIT-11-03 | components.css:60-63 | PASS | Full-bleed là opt-in tường minh qua `app__body--flush`; mặc định giữ safe margin 16 — có điều kiện và không phá margin. |
| KIT-11-04 | components.css:276-283; shots dashboard--empty vs --loaded | PASS | Section wrapper ép order cột header→content; shot empty vs loaded giữ order khi section ẩn/hiện. |
| KIT-11-05 | grep landscape/orientation = 0; tokens/size.css (chỉ modal max-width) | FAIL | Không có evidence phone landscape và không có max-readable-width cho reading/form (single full-width column); portrait-first nhưng scope chưa tài liệu hóa. |
| KIT-11-06 | components.css:18-31,632-646,654 | PASS | Layout fluid (.app 100%, flex, guard min-width:0); không tọa độ tuyệt đối cho content chính; bottom-nav absolute nhưng width fluid left:0/right:0 (chỉ chrome). |
| KIT-11-01 | SCOPE phone viewport + shoot widths 320-430 overflow-gated; committed range shots pending CI | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-11-05 | SCOPE.md: landscape unsupported; single readable column documented | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-11-01 | tool/ui_kit_shots/shoot.mjs WIDTHS [320,360,390,430]; governance/coverage-report.md (viewport-range: min 320 / default 390 / max 430); full matrix 0 unaccepted overflow ở mọi width | FIXED | Phone viewport range 320→390→430 verified; gutter keyline 16 + reflow fluid không overflow. |

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
