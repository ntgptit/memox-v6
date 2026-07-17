# KIT-07 — Theme Architecture

## Phạm vi

Audit schema, inheritance và mapping giữa theme; không đo contrast chi tiết hoặc visual dark-mode QA.

## Checklist

- [x] **KIT-07-01 — Mọi theme Current dùng cùng một semantic schema bắt buộc.**
  - **Cách kiểm:** VM-03 — diff token keys giữa base, light, dark và brand themes.
  - **Evidence mong đợi:** Key-diff report bằng 0 cho required tokens.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-07-02 — Base theme chứa default mappings; brand theme chỉ override tập được cho phép.**
  - **Cách kiểm:** VM-03 — diff overrides và đối chiếu override policy.
  - **Evidence mong đợi:** Override report với rationale từng khác biệt.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-07-03 — Alias chain không trỏ vòng hoặc trỏ tới token Deprecated.**
  - **Cách kiểm:** VM-03 — build alias graph và chạy cycle/deprecated-reference check.
  - **Evidence mong đợi:** Graph validation report bằng 0.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-07-04 — Missing override có fallback được định nghĩa, không tạo giá trị rỗng.**
  - **Cách kiểm:** VM-03 — remove/inspect override và kiểm fallback chain.
  - **Evidence mong đợi:** Fallback matrix và missing-value report.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-07-05 — Thêm theme mới có template coverage và regression gate rõ.**
  - **Cách kiểm:** VM-12 + VM-13 — kiểm contribution/release checklist cho theme.
  - **Evidence mong đợi:** Theme onboarding checklist và sample completed run.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-07-06 — Chuyển theme không thay đổi semantic hierarchy hoặc layout contract.**
  - **Cách kiểm:** VM-05 — so cùng component matrix giữa themes, bỏ qua khác biệt màu dự kiến.
  - **Evidence mong đợi:** Bằng chứng đặt cạnh nhau và danh sách lỗi về hierarchy hoặc layout.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-07-01 | tokens/colors.css:14-79 (light/:root) + 81-145 (dark); tool/ui_kit_shots/contrast.mjs:44-46 | PASS | Light và dark khai báo cùng bộ role token `--memox-<role>`; dark kế thừa light cho key không override; không thiếu required token. |
| KIT-07-02 | tokens/colors.css:94-101,127-135 (rationale comments), 147-157 (accent palettes); readme.md:25 | PASS | Dark chỉ override value, tên token frozen/additive-only; mỗi override có rationale trong comment; accent palette additive trong `:root`, theme-independent. |
| KIT-07-03 | tokens/elevation.css:17,26; tokens/radius.css:13-20; tokens/colors.css:10-11; grep deprecated = 0 | PASS | Alias graph nông và acyclic (`ring-focus` → `var(--memox-focus-ring)` một cấp); role alias radius/spacing là literal; Tokyo palette đã gỡ, không deprecated-in-place. |
| KIT-07-04 | tool/ui_kit_shots/contrast.mjs:44-46,136-141; components.css:960; tokens/*.css `:root` | PASS | CSS cascade fallback: dark kế thừa light; scale theme-independent định nghĩa một lần trong `:root`; có literal fallback `var(--memox-opacity-disabled,0.5)`; token thiếu sẽ hard-fail gate nên không có value rỗng. |
| KIT-07-05 | tool/ui_kit_shots/contrast.mjs (gate light+dark); readme.md:92; SKILL.md | FAIL | Regression gate tồn tại và chạy cho cả hai theme, nhưng không có onboarding checklist cho theme mới và không có sample completed run. |
| KIT-07-06 | ui_kits/memox-app/shots/*--light.png vs *--dark.png (vd dashboard--loaded); tokens spacing/radius/typography trong `:root` | PASS | Cùng cây component render cả hai theme, chỉ khác `data-theme`; token layout theme-independent nên hierarchy/layout bất biến giữa theme. |
| KIT-07-05 | governance/theme-onboarding.md checklist + worked sample run | FIXED | Remediation — audit v5 fix loop. |

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
