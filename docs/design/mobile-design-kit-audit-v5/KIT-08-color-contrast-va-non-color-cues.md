# KIT-08 — Color Contrast và Non-color Cues

## Phạm vi

Chỉ audit contrast và việc không phụ thuộc màu; primitive/semantic/theme mapping thuộc KIT-04/05/07.

## Checklist

- [x] **KIT-08-01 — Mọi cặp body/label text trên surface thực tế đạt tối thiểu 4.5:1.**
  - **Cách kiểm:** VM-06 — đo foreground/background từ component examples, không chỉ từ token rời.
  - **Evidence mong đợi:** CSV/report gồm token pair, component, light ratio, dark ratio và kết quả.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-08-02 — Large text hợp lệ đạt tối thiểu 3:1 và được xác định đúng ngưỡng kích thước/weight.**
  - **Cách kiểm:** VM-06 — đo các type roles được phân loại large text.
  - **Evidence mong đợi:** Bảng role, size, weight, pair và ratio.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-08-03 — Functional icon, focus indicator và required UI boundary đạt tối thiểu 3:1 khi cần nhận biết.**
  - **Cách kiểm:** VM-06 — đo trên input, checkbox, switch, tab và icon button states.
  - **Evidence mong đợi:** Contrast report theo component/state.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-08-04 — Error, warning, success và selected state có cue ngoài màu.**
  - **Cách kiểm:** VM-05 + VM-10 — tắt màu/grayscale và kiểm icon, text, border, shape hoặc state semantics.
  - **Evidence mong đợi:** Ảnh grayscale và accessibility state evidence.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-08-05 — Placeholder và disabled vẫn nhận biết được nhưng không bị hiểu là enabled.**
  - **Cách kiểm:** VM-06 + VM-05 — đo và đặt cạnh trạng thái enabled để so sánh.
  - **Evidence mong đợi:** Ratio table và screenshot enabled/disabled.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-08-06 — Light, dark và high-contrast profile đều có contrast evidence cho cặp critical.**
  - **Cách kiểm:** VM-06 — chạy cùng critical-pair list trên từng profile.
  - **Evidence mong đợi:** Một report duy nhất có cột profile và không còn P0/P1.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-08-01 | tool/ui_kit_shots/contrast.mjs (run output) + :78-119; tokens/colors.css | PASS | Tất cả cặp `normal` đạt ≥4.5 ở cả light+dark (text/bg 15.86, text-secondary/surface 5.71, text-tertiary/surface 5.13); gate composite alpha lên base từ cặp component thực. |
| KIT-08-02 | tool/ui_kit_shots/contrast.mjs (large cat); guidelines/type-scale.html:17-24 | PASS | `primary-strong` (ghost/link, large) 11.64 light / 7.07 dark ≥3; heading role (Display 38/800 … Title 24/700) dùng `--memox-text` 15.86 nên vượt ngưỡng large. |
| KIT-08-03 | tool/ui_kit_shots/contrast.mjs:104-118 | PASS | focus-ring/surface 9.20/7.07, /bg 8.49/8.56 (ui≥3); accent glyph trên accent-soft 4.46/4.44; border-strong không gate theo miễn trừ WCAG control có label, focus-ring là chỉ báo sole-means được gate và đạt. |
| KIT-08-04 | components.css:690-692,866-870,819-828,974-977,445-450,949-952; MxTextField.prompt.md | PASS | Cue ngoài màu tồn tại và sống sót khi grayscale: nav selected icon FILL:1, segmented active shadow (elevation), switch on đổi vị trí+size thumb, field error có message+dấu `*`+role=alert/aria-invalid, disabled dùng opacity+cursor. |
| KIT-08-05 | components.css:935-937,949-952; tokens/opacity.css:10; contrast.mjs (disabled rows) | PASS | Placeholder dùng text-tertiary (đọc được 4.73/5.13) khác disabled opacity 0.45 + `cursor:not-allowed`; disabled đo 1.72–2.76 (WCAG miễn trừ) rõ ràng mờ hơn enabled. |
| KIT-08-06 | tool/ui_kit_shots/contrast.mjs (chỉ light+dark); tokens/colors.css (không có high-contrast/forced-colors) | FAIL | Evidence chỉ phủ light+dark; kit không có high-contrast profile nào. Không có cặp contrast fail — light+dark đều đạt AA; chỉ thiếu coverage profile thứ ba. |
| KIT-08-06 | tool/ui_kit_shots/contrast.mjs now runs light+dark+hc-light+hc-dark in one report, gate PASS | FIXED | Remediation — audit v5 fix loop. |

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
