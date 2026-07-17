# KIT-39 — Dark Mode và High-contrast QA

## Phạm vi

Audit visual outcome của dark/high-contrast; schema mapping thuộc KIT-07, contrast số thuộc KIT-08.

## Checklist

- [x] **KIT-39-01 — Dark surface hierarchy phân biệt background, surface và elevated surface bằng visual cue phù hợp.**
  - **Cách kiểm:** VM-05 — compare representative screen surfaces.
  - **Evidence mong đợi:** Annotated dark screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-39-02 — Shadow/elevation được điều chỉnh hoặc thay bằng surface/border cue.**
  - **Cách kiểm:** VM-05 — compare overlay/card depth light vs dark.
  - **Evidence mong đợi:** Depth comparison evidence.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-39-03 — Illustration, logo, photo overlay và transparent asset không có viền/nền lỗi.**
  - **Cách kiểm:** VM-14 + VM-05 — inspect dark asset gallery.
  - **Evidence mong đợi:** Báo cáo kiểm tra asset trong dark mode.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-39-04 — Pressed, selected, disabled, focus và feedback states vẫn phân biệt trong dark.**
  - **Cách kiểm:** VM-04 + VM-05 — render dark state matrix.
  - **Evidence mong đợi:** Dark state contact sheet.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-39-05 — High-contrast profile tăng boundary/focus mà không đảo semantic hierarchy.**
  - **Cách kiểm:** VM-05 + VM-10 — inspect high-contrast samples.
  - **Evidence mong đợi:** High-contrast state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-39-06 — Không dùng automatic inversion cho brand/media asset ngoài policy.**
  - **Cách kiểm:** VM-14 + VM-12 — inspect treatment rules.
  - **Evidence mong đợi:** Asset treatment policy and exceptions.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-39-01 | `tokens/colors.css:81-87` (bg #141220, surface #252338, surface-raised #302d46, surface-muted #1c1a2b); `audit/_sheets/14-dark.png` | PASS | Dark phân tầng background/surface/elevated bằng lightness; card nổi rõ trên canvas near-black. |
| KIT-39-02 | `tokens/colors.css:82` ("elevation by lightness"); `tokens/elevation.css` (dark = hairline ring + ambient); `14-dark.png` | PASS | Dark thay shadow nặng bằng surface lightness + border cue. |
| KIT-39-03 | `readme.md` (no photographic imagery); `components/core/MxAvatar.jsx:10` (initials fallback); icon = Material Symbols font | PASS | Không có raster illustration/photo/transparent asset để lỗi viền trong dark. |
| KIT-39-04 | `tokens/colors.css:137-142` (state-hover/pressed/selected/disabled/focus-ring dark); `14-dark.png`, `shots/flashcard-list--long-text--dark.png` (badge Due/Mastered/New) | PASS | State và feedback vẫn phân biệt trong dark. |
| KIT-39-05 | `tokens/colors.css` — chỉ light + dark; không có high-contrast profile; `KIT-08-color-contrast-va-non-color-cues.md:34` kỳ vọng profile high-contrast | FAIL | Thiếu hẳn high-contrast profile; không có boundary/focus tăng cường. |
| KIT-39-06 | `tokens/colors.css:1-12` (per-theme value, no runtime override, no CSS invert); không có brand/media raster | PASS | Không dùng automatic inversion; theme bằng token theo từng chế độ. |
| KIT-39-05 | tokens/high-contrast.css high-contrast profile | FIXED | Remediation — audit v5 fix loop. |

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
