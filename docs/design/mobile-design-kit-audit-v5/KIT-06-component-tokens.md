# KIT-06 — Component Tokens

## Phạm vi

Audit token scoped theo component; không audit component anatomy hoặc full theme architecture.

## Checklist

- [x] **KIT-06-01 — Component token chỉ tồn tại khi semantic token không đủ diễn đạt state/slot lặp lại.**
  - **Cách kiểm:** VM-03 + VM-12 — review rationale và usage count của từng component token.
  - **Evidence mong đợi:** Danh sách token có rationale, aliases và số consumer.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-06-02 — Tên component token thể hiện component, slot, property và state theo convention.**
  - **Cách kiểm:** VM-01 — validate names bằng schema.
  - **Evidence mong đợi:** Naming validation report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-06-03 — Mọi component token alias về semantic token phù hợp, không bypass theme.**
  - **Cách kiểm:** VM-03 — trace alias chain tới semantic layer.
  - **Evidence mong đợi:** Alias graph không có direct primitive ngoài approved exception.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-06-04 — Không có component token chỉ dùng cho một instance hoặc một screen.**
  - **Cách kiểm:** VM-01 — count references và tìm screen-specific names.
  - **Evidence mong đợi:** Usage-count report; token one-off được loại hoặc justified.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-06-05 — State token cho disabled, error, selected và focus không dùng opacity tùy ý.**
  - **Cách kiểm:** VM-03 + VM-04 — inspect state aliases trong representative components.
  - **Evidence mong đợi:** State-token matrix và links tới component examples.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-06-06 — Component token không còn sử dụng được được deprecate kèm replacement.**
  - **Cách kiểm:** VM-13 — kiểm metadata và usage remaining.
  - **Evidence mong đợi:** Deprecation table, replacement và remaining usage count.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-06-01 | `tokens/component.css:1-51` header ("Fixed intrinsic sizes ... every raw px that used to live in components.css"); token là kích thước control (chip-height, switch-*, badge-*, avatar-*, icon-tile-*, icon-btn, search-dock, nav-pill, segmented) mà scale chung không diễn đạt được | PASS | Chỉ tồn tại cho dimension intrinsic (vd switch M3 52×32, thumb travel 20px) — semantic/scale không diễn đạt được; có rationale, mỗi token consumer là component tương ứng. |
| KIT-06-02 | `tokens/component.css`: schema `--memox-comp-<component>-<prop>[-state]` — `comp-chip-height`, `comp-switch-thumb-on`, `comp-badge-pad-x`, `comp-nav-pill-width`, `comp-segmented-seg-height` | PASS | Tên thể hiện component + property (+ state như `-on`) nhất quán theo convention. |
| KIT-06-03 | `tokens/component.css` toàn bộ là dimension token theme-independent (header:4); không có component COLOR token; màu component lấy trực tiếp từ semantic role token qua `var()` | PASS | Không token nào bypass theme màu; dimension giữ px literal là đúng (ngoại lệ được duyệt cho kích thước intrinsic M3, không có tầng semantic size để alias). |
| KIT-06-04 | `tokens/component.css` mỗi `comp-*` map tới một `Mx*` component tái dùng (chip/switch/badge/avatar/icon-tile/icon-btn/search-dock/bottom-nav/segmented); không có `comp-<screen>-*` | PASS | Không có token one-off theo instance/screen. |
| KIT-06-05 | State qua token đặt tên: `--memox-state-hover/pressed/selected/disabled`, `--memox-focus-ring` (`colors.css:72-76`), `--memox-error*`, opacity đặt tên `--memox-opacity-disabled..label` (`opacity.css:10-14`), `--memox-stroke-focus`/`--memox-ring-focus`; `_adherence.oxlintrc.json` cấm giá trị thô | PASS | disabled/error/selected/focus dùng token màu + opacity + stroke đặt tên, không opacity tùy ý inline. |
| KIT-06-06 | Header token "Names frozen / additive only" (`component.css:2`, `colors.css:8-9`); không có token nào gắn nhãn deprecated; mọi `comp-*` đều còn consumer | PASS | Hợp đồng additive-only, 0 token deprecated → bảng deprecation rỗng là hợp lệ. |

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
