# KIT-03 — Naming Convention

## Phạm vi

Kiểm tra tính nhất quán tên; không đánh giá giá trị token hay visual.

## Checklist

- [x] **KIT-03-01 — Primitive, semantic và component token dùng ba cấu trúc tên phân biệt rõ.**
  - **Cách kiểm:** VM-01 — export token names và phân loại bằng pattern.
  - **Evidence mong đợi:** Danh sách regex/convention và report tên không khớp.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-03-02 — Semantic token mô tả vai trò, không chứa màu hoặc giá trị cụ thể.**
  - **Cách kiểm:** VM-01 — tìm tên có color names, hex, số scale trong semantic collection.
  - **Evidence mong đợi:** Danh sách vi phạm bằng 0 hoặc issue migration.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-03-03 — Component, slot và property dùng chung vocabulary như leading/content/trailing.**
  - **Cách kiểm:** VM-04 — so sánh property names giữa các component tương tự.
  - **Evidence mong đợi:** Glossary chuẩn và report tên lệch.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-03-04 — Variant và state được đặt theo mục đích, không theo màu hiển thị.**
  - **Cách kiểm:** VM-04 — lọc property values chứa màu hoặc tên tạm.
  - **Evidence mong đợi:** Danh sách variant/state names đạt convention.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-03-05 — File, page và checklist không dùng tên tạm như final-final, copy hoặc new.**
  - **Cách kiểm:** VM-11 — quét filename/page name bằng pattern cấm.
  - **Evidence mong đợi:** Scan report bằng 0.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-03-06 — Tên không phụ thuộc Flutter, React Native, SwiftUI hoặc framework khác.**
  - **Cách kiểm:** VM-01 + VM-12 — tìm framework keywords trong public token/component names.
  - **Evidence mong đợi:** Search report và danh sách ngoại lệ được phê duyệt.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-03-01 | Primitive `--memox-<scale>-<step>` (`tokens/spacing.css` space-0..12, `radius.css` xs..2xl, `typography.css` font-size-*, `size.css`, `stroke.css`, `icon-size.css`, `motion.css` duration-*); Semantic `--memox-<role>` (`tokens/colors.css` bg/surface/text/primary/success…); Component `--memox-comp-<component>-<prop>` (`tokens/component.css`) | PASS | Ba cấu trúc tên phân biệt rõ: scale+step, role-word, và tiền tố `comp-`. |
| KIT-03-02 | `tokens/colors.css:14-79` role token không chứa hex/số scale trong tên; các token có tên màu (`--memox-palette-violet/indigo/…`, `colors.css:150-157`) là palette primitive (hue người dùng chọn), không phải role semantic | PASS | Tầng semantic (role) sạch tên màu; token tên-màu chỉ nằm ở tầng palette primitive đúng chỗ. |
| KIT-03-03 | `components/core/MxButton.d.ts:11-14` (leading/trailingIcon); `MxChip.d.ts:5`, `MxLink.d.ts:5-8`, `navigation/MxSearchDock.d.ts:11-12` (trailing), `surfaces/MxContextualAppBar.d.ts:20-37`, `MxSectionHeader.d.ts:7-15` (leading/trailing) | PASS | Vocabulary leading/trailing dùng nhất quán qua 7 component. |
| KIT-03-04 | Variant/state values trong `components/*/*.d.ts`: primary/secondary/outline/ghost/filled/flat/muted/accent/success/warning/error/root/nested/search/selection/modal | PASS | Đặt theo mục đích/vai trò, không có tên màu hiển thị thô (không có blue/red-500…). |
| KIT-03-05 | `find` toàn kit theo pattern final/copy/new/draft/wip/old/temp/v[0-9] | PASS | Không có tên tạm; các khớp là dương tính giả ("ScaffOLD", "FINALizingView" là thuật ngữ sản phẩm). |
| KIT-03-06 | Grep public names (`--memox-*`, `Mx*`) cho flutter/swiftui/reactnative/android/ios: 0 kết quả; "react"/ReactNode chỉ xuất hiện ở kiểu implementation trong `.d.ts` | PASS | Tên token/component công khai không phụ thuộc framework. |

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
