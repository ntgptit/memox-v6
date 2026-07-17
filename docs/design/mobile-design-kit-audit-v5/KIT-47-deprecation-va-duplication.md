# KIT-47 — Deprecation và Duplication

## Phạm vi

Audit detection, migration và removal của legacy/duplicate artifacts.

## Checklist

- [x] **KIT-47-01 — Có scan định kỳ duplicate token, component, style và documentation.**
  - **Cách kiểm:** VM-11 — run exact and near-duplicate scans.
  - **Evidence mong đợi:** Báo cáo quét trùng lặp.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-47-02 — Deprecated artifact có replacement, reason, since-version và removal target.**
  - **Cách kiểm:** VM-13 — validate deprecation metadata.
  - **Evidence mong đợi:** Bảng độ đầy đủ metadata deprecation.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-47-03 — New usage của artifact Deprecated bị chặn trong governance.**
  - **Cách kiểm:** VM-13 + VM-02 — inspect contribution/review rule and current usages.
  - **Evidence mong đợi:** Liên kết policy và số lượt sử dụng mới.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-47-04 — Migration map old→new nêu visual/behavior differences.**
  - **Cách kiểm:** VM-13 + VM-12 — inspect migration docs.
  - **Evidence mong đợi:** Bảng ánh xạ migration.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-47-05 — Không xóa artifact khi Current template còn dùng.**
  - **Cách kiểm:** VM-02 — usage scan before removal.
  - **Evidence mong đợi:** Báo cáo số lượt sử dụng còn lại bằng 0.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-47-06 — Duplicate resolution chọn canonical, merge properties/states và cập nhật inventory/docs.**
  - **Cách kiểm:** VM-11 + VM-13 — review resolved duplicate sample.
  - **Evidence mong đợi:** Biên bản xử lý và báo cáo quét sau migration.
  - **Severity mặc định nếu không đạt:** `P3`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-47-01 | `_adherence.oxlintrc.json` (chỉ check raw values, không dedup), scan thủ công tokens/colors.css, spacing.css, radius.css | FAIL | Không có tooling scan duplicate định kỳ cho token/component/style/doc. Scan thủ công chỉ thấy semantic alias by-design (info=primary, focus-ring=primary #4b3a8c; gutter=16px, touch-min=48px) — không có duplicate artifact có hại. |
| KIT-47-02 | `readme.md:13` (Tokyo palette "legacy"), `readme.md:57` (large app bar "retired") | FAIL | Có ghi chú legacy dạng văn xuôi nhưng không có bảng deprecation cấu trúc với replacement/reason/since-version/removal-target. |
| KIT-47-03 | `readme.md:13` ("do not reintroduce"), `_adherence.oxlintrc.json` | FAIL | Chỉ có lời khuyên văn xuôi; không có governance/lint rule chặn new usage của artifact deprecated. |
| KIT-47-04 | `readme.md:13,57` (Tokyo→deep-violet, large-bar→compact) | FAIL | Migration mô tả dạng văn xuôi, không có migration map old→new nêu visual/behavior differences có cấu trúc. |
| KIT-47-05 | `readme.md:7` (additive-only), `ui_kits/memox-app/_features/README.md` (data-mx-node stability), `tool/parity/` | FAIL | Contract additive-only + parity keyed trên data-mx-node giảm rủi ro xóa nhầm, nhưng không có usage-scan-before-removal process hay báo cáo usage=0. |
| KIT-47-06 | Toàn kit (không có duplicate-resolution record) | FAIL | Không có biên bản xử lý duplicate/chọn canonical — chưa cần vì không có duplicate có hại, nhưng process vắng. |
| KIT-47-01 | governance/duplicate-scan.md scan process + recorded result | FIXED | Remediation — audit v5 fix loop. |
| KIT-47-02 | governance/deprecation-policy.md structured deprecation table | FIXED | Remediation — audit v5 fix loop. |
| KIT-47-03 | governance/deprecation-policy.md lint-block rule for deprecated usage | FIXED | Remediation — audit v5 fix loop. |
| KIT-47-04 | governance/deprecation-policy.md migration map w/ visual/behavior diffs | FIXED | Remediation — audit v5 fix loop. |
| KIT-47-05 | governance/deprecation-policy.md usage-scan-before-removal record | FIXED | Remediation — audit v5 fix loop. |
| KIT-47-06 | governance/deprecation-policy.md + duplicate-scan.md resolution process | FIXED | Remediation — audit v5 fix loop. |

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
