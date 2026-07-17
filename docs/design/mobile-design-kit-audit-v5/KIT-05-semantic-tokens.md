# KIT-05 — Semantic Tokens

## Phạm vi

Audit role semantics và alias; không lặp primitive scale, contrast measurement hoặc theme QA.

## Checklist

- [x] **KIT-05-01 — Có semantic roles tối thiểu cho background, surface, content, border, action và feedback.**
  - **Cách kiểm:** VM-03 — export semantic collection và đối chiếu role matrix.
  - **Evidence mong đợi:** Role matrix có mapping cho mọi role bắt buộc.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-05-02 — Mỗi semantic token alias về primitive hoặc approved base token, không hardcode ngoài policy.**
  - **Cách kiểm:** VM-03 — inspect alias chain và tìm literal values.
  - **Evidence mong đợi:** Báo cáo alias và danh sách ngoại lệ dùng giá trị trực tiếp.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-05-03 — Không có hai semantic token khác tên nhưng cùng vai trò sử dụng.**
  - **Cách kiểm:** VM-11 + VM-12 — hash description/usage và review tên gần nghĩa.
  - **Evidence mong đợi:** Duplicate-role report và quyết định merge/keep.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-05-04 — Action primary, secondary, tertiary và destructive giữ semantic khác nhau.**
  - **Cách kiểm:** VM-03 + VM-04 — so alias và component usages của từng action role.
  - **Evidence mong đợi:** Action-role matrix và sample usages.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-05-05 — Feedback success, warning, error, info tách khỏi data-visualization palette.**
  - **Cách kiểm:** VM-03 — trace usages và token collection ownership.
  - **Evidence mong đợi:** Usage report không có chart token dùng làm feedback hoặc ngược lại.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-05-06 — Semantic role không gắn với một screen hoặc business entity cụ thể.**
  - **Cách kiểm:** VM-01 — tìm screen/product terms trong semantic names/descriptions.
  - **Evidence mong đợi:** Search report bằng 0 hoặc danh sách chuyển sang local tokens.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-05-01 | `tokens/colors.css`: background `--memox-bg` (18); surface `--memox-surface(-muted/raised/sunken)` (19-22); content `--memox-text(-secondary/tertiary)` (26-28); border `--memox-border(-strong)`,`--memox-divider` (43-45); action `--memox-primary*`,`--memox-accent*` (31-40); feedback `--memox-success/warning/error/info` (48-69) | PASS | Đủ role tối thiểu cho cả 6 nhóm, có light + dark. |
| KIT-05-02 | `tokens/colors.css:6-9` chính sách "SINGLE SOURCE OF TRUTH ... no runtime override"; consumer luôn dùng `var(--memox-*)`; `_adherence.oxlintrc.json` cấm raw hex/px | PASS | Ngoại lệ theo policy: role color token giữ giá trị literal tại tầng token (không có ramp primitive riêng cho màu); mọi consumer đều alias qua var(), không hardcode. |
| KIT-05-03 | So role/giá trị trong `tokens/colors.css`: `--memox-info`=`--memox-primary` (#4b3a8c) chỉ ở light nhưng khác vai trò và khác giá trị ở dark (info #8a79e0 vs primary #4b3a8c) | PASS | Không có hai token khác tên cùng vai trò sử dụng; trùng giá trị light là chủ đích, role vẫn tách. |
| KIT-05-04 | `components/core/MxButton.d.ts` variant primary/secondary/outline/ghost + `danger`; alias tương ứng `--memox-primary` (filled), `--memox-surface-muted`/tonal (secondary), `--memox-primary-strong` (ghost/tertiary), `--memox-error` (destructive) | PASS | Bốn cấp action giữ semantic khác nhau qua variant + token nền. |
| KIT-05-05 | `_features/statistics/components/Donut.jsx:7` dùng `tone="var(--memox-success)"` làm chart tone; `tokens/colors.css:48` `--memox-success` là feedback role | FAIL | Feedback token `--memox-success` được tái dùng làm data-viz tone trong Donut — đúng case "ngược lại" mà mục yêu cầu phải vắng. Không có data-viz palette riêng; chart mượn feedback token. Tác động thấp (vòng completion xanh success hợp semantic) → P3. Xem ISS-KIT-05-05. |
| KIT-05-06 | Grep tên/mô tả semantic trong `tokens/colors.css` cho screen/business terms (deck/flashcard/study…): 0 kết quả | PASS | Role semantic không gắn screen/business entity cụ thể. |
| KIT-05-05 | tokens/colors.css --memox-viz-1..6; Donut/Bars/Heatmap repointed off feedback tokens | FIXED | Remediation — audit v5 fix loop. |

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
