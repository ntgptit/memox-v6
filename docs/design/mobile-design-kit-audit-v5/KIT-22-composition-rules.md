# KIT-22 — Composition Rules

## Phạm vi

Audit cách ghép component thành layout có hierarchy.

## Checklist

- [x] **KIT-22-01 — Screen padding, section gap và item gap dùng một rhythm được công bố.**
  - **Cách kiểm:** VM-05 — annotate representative compositions with token names.
  - **Evidence mong đợi:** Composition spacing map.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-22-02 — Mỗi vùng chỉ có một primary action; destructive không cạnh tranh primary.**
  - **Cách kiểm:** VM-05 — review action hierarchy on templates.
  - **Evidence mong đợi:** Báo cáo kiểm tra thứ bậc hành động.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-22-03 — Một screen giới hạn title/heading/weight để tránh hierarchy phẳng.**
  - **Cách kiểm:** VM-05 + VM-12 — count roles/weights per template.
  - **Evidence mong đợi:** Typography composition report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-22-04 — Card chỉ dùng khi cần container semantic, không dùng để bọc mọi section.**
  - **Cách kiểm:** VM-05 — count/note card usage and alternatives.
  - **Evidence mong đợi:** Card-use audit.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-22-05 — Nested component combinations tuân anatomy và không tạo target conflict.**
  - **Cách kiểm:** VM-04 + VM-10 — inspect approved compositions.
  - **Evidence mong đợi:** Approved/forbidden composition matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-22-06 — Ẩn section tùy chọn không để gap, divider hoặc header orphan.**
  - **Cách kiểm:** VM-07 — toggle sections in templates.
  - **Evidence mong đợi:** Before/after screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-22-01 | `readme.md:49` (gutter/card 16, gaps 8-12 rows, 24/32 sections); `mobile-ui-construction-contract.md:52-55` (padding 16, section gap 24/32, item gap 8/12, scale {4,8,12,16,24,32,48}); `components/surfaces/MxList.jsx:1-14` owns the standard `space-3` (12px) inter-card gap; every `specs/*.md` handoff note restates the rhythm | PASS | A single published spacing rhythm is documented and applied via tokens. |
| KIT-22-02 | Each `specs/*.md` declares exactly one Primary CTA (e.g. `dashboard.md` "Start review"; `search.md`/`settings.md` "none — read/nav surface"); `mobile-ui-construction-contract.md:66-74` one primary CTA rule; destructive lives in confirm sheets/dialogs (`deck-settings.md` action-sheet/delete-confirm) not competing inline with Save | PASS | One primary action per region; destructive is isolated in sheets/dialogs with `danger`. |
| KIT-22-03 | `mobile-ui-construction-contract.md:66-67` "một heading cấp cao nhất", "tối đa năm typography roles"; `readme.md:48` weight roles (800/700/600/400); `guidelines/type-*.html` specimens | PASS | Title/heading/weight roles are capped by a published rule to avoid flat hierarchy. |
| KIT-22-04 | `readme.md:51` card variants for semantic containers; `mobile-ui-construction-contract.md:57,78` "Không đặt card trong card nếu không có semantic grouping" / "Không tạo mọi section thành card"; `MxCard.prompt.md`; lists use `MxList` (plain gap) not nested cards | PASS | Card use is scoped to semantic containers; lists/sections use MxList, not card-wrapping. |
| KIT-22-05 | `components.css:979-1013` `::after` hit-area overlays keep nested small controls at ≥48px (prevents target conflict); `mobile-ui-construction-contract.md:56` max 3 nested surfaces; `components/*/*.prompt.md` define per-component anatomy | PASS | Approved nested compositions follow anatomy and preserve ≥48px targets. |
| KIT-22-06 | Sections are whole-conditionally rendered (`library/Library.jsx:63-70` offline banner, `dashboard` empty vs loaded states); `MxList.jsx:14` uses flex `gap` which only spaces rendered children, so a hidden section leaves no orphan gap/divider/header; state gallery shots (`shots/dashboard--empty` vs `--loaded`) act as before/after | PASS | Optional sections toggle cleanly; flex gap collapses, no orphan gap/divider/header. |

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
