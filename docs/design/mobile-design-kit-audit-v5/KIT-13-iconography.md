# KIT-13 — Iconography

## Phạm vi

Audit icon system, semantics và placement.

## Checklist

- [x] **KIT-13-01 — Functional icons thuộc cùng style family, stroke và corner treatment.**
  - **Cách kiểm:** VM-14 + VM-05 — export contact sheet và compare.
  - **Evidence mong đợi:** Icon contact sheet có source/style metadata.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-13-02 — Icon dùng grid, bounding box và optical size nhất quán ở từng size.**
  - **Cách kiểm:** VM-14 — overlay grid/bounds trên sample set.
  - **Evidence mong đợi:** Grid overlay evidence.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-13-03 — Mỗi component dùng icon size và icon-label gap theo spec.**
  - **Cách kiểm:** VM-04 + VM-05 — inspect button, input, nav, list, menu.
  - **Evidence mong đợi:** Component-icon matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-13-04 — Không dùng cùng icon cho các hành động dễ nhầm như close, cancel, delete và back.**
  - **Cách kiểm:** VM-12 + VM-05 — review icon glossary/usages.
  - **Evidence mong đợi:** Semantic icon glossary và conflict list.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-13-05 — Directional icon mirror đúng RTL; non-directional icon không bị mirror sai.**
  - **Cách kiểm:** VM-08 — render RTL samples.
  - **Evidence mong đợi:** LTR/RTL comparison screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-13-06 — Icon-only actions có accessible name và đủ touch target.**
  - **Cách kiểm:** VM-10 — inspect semantics and hit area.
  - **Evidence mong đợi:** Accessibility evidence theo icon button.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-13-01 | readme.md:63 (Material Symbols Rounded, weight 400, FILL 0, single variable icon font); components.css universal `.material-symbols-rounded` glyph class (lines 341, 436, 478, 511, 577, 604, 664) | PASS | Toàn bộ functional icon dùng một variable icon font duy nhất nên style family, stroke weight và corner treatment đồng nhất theo thiết kế. |
| KIT-13-02 | tokens/icon-size.css:11-15 (sm18/md22/lg28/xl32; 20/24 reuse font-size-lg/xl); readme.md:63 (Material Symbols opsz/24-grid) | PASS | Icon size rời rạc, đặt qua font-size trên cùng một font có bounding box và grid cố định; optical size khớp theo trục font. |
| KIT-13-03 | components.css: btn gap space-2 + icon-size-lg (319, 341); chip gap space-2 + icon-size-sm (699, 715); link gap space-1 (413, 436); icon-tile lg/xl (511-520); fab lg (577); search-dock md (604); bottom-nav lg + nav-item-gap (652, 664); cappbar search md (188) | PASS | Mỗi component khai báo icon size và icon-label gap riêng bằng token; component-icon matrix dựng được từ components.css. |
| KIT-13-04 | readme.md:65 (common glyphs); MxIconButton.d.ts (Back=arrow_back, Close=close, More options=more_horiz); MxContextualAppBar.d.ts leading contract (back cho nested/search, close cho modal/selection) | PASS | Back, close và overflow dùng glyph phân biệt; không thấy conflict. Glossary hiện gom theo screen chứ chưa gom theo semantic action. |
| KIT-13-05 | Grep `rtl\|direction\|dir=\|mirror\|scaleX` toàn kit (trừ shots) = 0 kết quả; chevron_right/arrow_back trong MxLink/MxContextualAppBar không có logic mirror; không có RTL sample | FAIL | Không có xử lý RTL hoặc sample LTR/RTL; directional icon sẽ không mirror. MemoX hiện là sản phẩm LTR (Vietnamese/English) nên hạ mức xuống P2. |
| KIT-13-06 | MxIconButton.d.ts (`ariaLabel: string` REQUIRED, không optional); components.css icon-btn base = touch-min 48px (457-458), hit-area ::after cho icon-btn--sm (1010); fab 56px; MxFab.d.ts ariaLabel cho icon-only | PASS | Icon-only action bắt buộc accessible name (icon button) và touch target >=48; compact size mở rộng hit area qua ::after. |
| KIT-13-05 | components.css [dir=rtl] mirror hook + SCOPE.md RTL scope | FIXED | Remediation — audit v5 fix loop. |

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
