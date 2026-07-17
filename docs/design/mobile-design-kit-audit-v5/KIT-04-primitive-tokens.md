# KIT-04 — Primitive Tokens

## Phạm vi

Chỉ audit raw scales/values; không audit semantic role, theme mapping hoặc contrast.

## Checklist

- [x] **KIT-04-01 — Color primitive có palette và scale hữu hạn, không có bước trùng ngoài chủ đích.**
  - **Cách kiểm:** VM-01 + VM-11 — export giá trị màu, group theo value và so scale.
  - **Evidence mong đợi:** Palette table; duplicate-value report có rationale.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-04-02 — Typography primitives tách family, size, weight, line-height và letter-spacing.**
  - **Cách kiểm:** VM-01 — inspect/export raw typography variables/styles.
  - **Evidence mong đợi:** Bảng primitive typography không chứa semantic role.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-04-03 — Spacing và sizing primitives dùng scale thống nhất, không có giá trị rời không ghi exception.**
  - **Cách kiểm:** VM-01 — export numeric values và so với allowed scale.
  - **Evidence mong đợi:** Histogram giá trị; exception register.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-04-04 — Radius, border width, opacity và elevation primitives có số mức hữu hạn.**
  - **Cách kiểm:** VM-01 — export từng collection và kiểm count/order.
  - **Evidence mong đợi:** Bảng scale theo property cùng usage count.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-04-05 — Motion primitives có duration, easing và reduced-motion value rõ.**
  - **Cách kiểm:** VM-15 — inspect token set và chạy sample transitions.
  - **Evidence mong đợi:** Token table và clip/screenshot normal vs reduced motion.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-04-06 — Primitive token không gắn tên component, screen hoặc semantic meaning.**
  - **Cách kiểm:** VM-01 — search names theo component/screen/role glossary.
  - **Evidence mong đợi:** Violation report bằng 0 hoặc migration issues.
  - **Severity mặc định nếu không đạt:** `P3`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-04-01 | `tokens/colors.css:150-157` palette primitive 6 hue hữu hạn (indigo/violet/green/coral/amber/cyan); các trùng giá trị (vd `--memox-surface-raised`=`--memox-surface`=#ffffff, `--memox-info`=`--memox-primary`=#4b3a8c) có rationale trong comment `colors.css:94-96,65-69` | PASS | Palette hữu hạn; trùng bước là chủ đích (tái dùng tông, info tái dùng brand) có ghi chú. |
| KIT-04-02 | `tokens/typography.css:14-48` tách `--memox-font-sans/mono`, `font-size-xs..4xl`, `font-weight-regular..extrabold`, `line-height-none..relaxed`, `letter-spacing-tight..caps` | PASS | Năm nhóm primitive typography tách bạch, không nhúng semantic role. |
| KIT-04-03 | `tokens/spacing.css:6-19` scale 4px base (0,2,4,8,12,16,20,24,32,40,48,64,80,96); `tokens/size.css:8-19` element-size scale riêng có header ghi rõ mục đích | PASS | Scale spacing thống nhất 4px; các giá trị intrinsic (size 74px, comp 34/52px) là exception có ghi chú trong header file. |
| KIT-04-04 | `radius.css` 6 mức + alias; `stroke.css` 5 mức (1/1.5/2/3/4px); `opacity.css` 5 mức; `elevation.css` 6 shadow (light+dark); `icon-size.css` 4 mức | PASS | Mỗi property có số mức hữu hạn, có thứ tự. |
| KIT-04-05 | `tokens/motion.css:8-23` có duration (instant/fast/base/slow + flash/pulse) + easing (standard/decelerate/accelerate); reduced-motion CHỈ xử lý ở tầng component (`components.css:206-210` cappbar, `:1098` spinner) | FAIL | Không có reduced-motion value/token ở tầng primitive; xử lý reduced-motion chỉ ở 2 block media-query mức component, chưa phủ toàn bộ animation. |
| KIT-04-06 | `tokens/spacing.css:26-29` chứa token tên theo element/component: `--memox-appbar-height`, `--memox-bottom-nav-height`, `--memox-fab-size` nằm trong file scale primitive | FAIL | Token tên component/element (appbar/bottom-nav/fab) đặt lẫn trong tầng primitive spacing; nên tách thành layout token riêng. Các scale số thuần (space/size/radius/stroke/opacity/icon) thì sạch. |
| KIT-04-05 | tokens/motion.css --memox-duration-none + components.css reduced-motion reset | FIXED | Remediation — audit v5 fix loop. |
| KIT-04-06 | tokens/spacing.css --memox-layout-* aliases | FIXED | Remediation — audit v5 fix loop. |

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
