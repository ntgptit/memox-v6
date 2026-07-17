# KIT-12 — Shape, Border và Elevation

## Phạm vi

Audit shape/border/depth system; color contrast của border thuộc KIT-08.

## Checklist

- [x] **KIT-12-01 — Radius levels hữu hạn và mỗi level có use case rõ.**
  - **Cách kiểm:** VM-01 + VM-12 — export radius tokens và map usages.
  - **Evidence mong đợi:** Radius usage table.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-12-02 — Nested surfaces không tạo radius conflict hoặc clipping ngoài chủ đích.**
  - **Cách kiểm:** VM-05 — inspect card-in-sheet, input-in-card, media containers.
  - **Evidence mong đợi:** Annotated nested-shape screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-12-03 — Border width/style dùng token và không làm layout nhảy giữa states.**
  - **Cách kiểm:** VM-04 + VM-05 — compare default/focus/error/selected states.
  - **Evidence mong đợi:** State overlay evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-12-04 — Divider, container border và focus ring là ba roles phân biệt.**
  - **Cách kiểm:** VM-03 + VM-05 — trace tokens và inspect examples.
  - **Evidence mong đợi:** Bảng ánh xạ vai trò và ảnh minh họa đại diện.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-12-05 — Elevation levels hữu hạn và mỗi overlay/card type dùng đúng level.**
  - **Cách kiểm:** VM-01 + VM-04 — map component usages to elevation tokens.
  - **Evidence mong đợi:** Elevation matrix.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-12-06 — Dark/high-contrast treatment không chỉ sao chép shadow của light theme.**
  - **Cách kiểm:** VM-05 — compare depth cues across profiles.
  - **Evidence mong đợi:** Side-by-side depth evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-12-01 | tokens/radius.css:5-20; guidelines/radius-scale.html; components.css (usage) | PASS | 6 level cơ sở (xs6–2xl28) + role alias card20/tile16/control12/field14/chip999, mỗi role có use case; component bind (card→card, btn→control, field→field). |
| KIT-12-02 | tokens/radius.css; components.css:222,507,916; shots (card có tile/chip lồng) | PASS | Radius đồng tâm giảm dần vào trong: card20 > tile16 > field14 > chip999; avatar overflow:hidden là clip ảnh chủ đích; không xung đột/clip ngoài ý. |
| KIT-12-03 | tokens/stroke.css; components.css:337-339,387,400,707,724,805,821 | PASS | Border render bằng inset box-shadow (chip/outline/switch/focus) nên đổi state là đổi màu, không đổi hình học → không nhảy layout. |
| KIT-12-04 | tokens/colors.css:43-45,76; tokens/stroke.css; tokens/elevation.css:17 | PASS | Ba họ token phân biệt — divider (α 0.08/0.10), border/border-strong (container), focus-ring + ring-focus 3px. |
| KIT-12-05 | tokens/elevation.css:8-27; components.css:223,563,644,483,249 | PASS | 5 level hữu hạn (sm/card/lg/fab/nav) ánh xạ đúng type — card→card, fab→fab, nav→nav, dock/filled→sm, interactive hover→lg. |
| KIT-12-06 | tokens/elevation.css:8-27; tokens/colors.css:83-87; shots *--light vs *--dark | PASS | Dark thiết kế lại depth chứ không sao chép: light dùng cast violet-grey, dark dùng hairline ring + ambient sâu + thang surface theo lightness. |

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
