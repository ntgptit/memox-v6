# KIT-43 — Component Documentation

## Phạm vi

Audit completeness tài liệu cho từng component.

## Checklist

- [x] **KIT-43-01 — Mỗi Current component có purpose, when-to-use và when-not-to-use.**
  - **Cách kiểm:** VM-12 — run documentation completeness scan.
  - **Evidence mong đợi:** Component doc coverage table.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-43-02 — Anatomy, slots, variants, sizes và supported combinations được ghi.**
  - **Cách kiểm:** VM-12 + VM-04 — compare docs with component properties.
  - **Evidence mong đợi:** Doc-vs-component diff.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-43-03 — State matrix, interaction, theme và platform adaptation được ghi.**
  - **Cách kiểm:** VM-12 — check required sections.
  - **Evidence mong đợi:** Required-section report.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-43-04 — Content limits, localization, RTL và accessibility requirements được ghi.**
  - **Cách kiểm:** VM-12 + VM-08 — inspect documentation examples.
  - **Evidence mong đợi:** Documentation evidence links.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-43-05 — Có do/don't và edge-case examples dùng instance Current.**
  - **Cách kiểm:** VM-02 + VM-12 — inspect example linkage/status.
  - **Evidence mong đợi:** Example linkage report.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-43-06 — Version, owner, source link và deprecation status không thiếu.**
  - **Cách kiểm:** VM-13 + VM-12 — validate metadata.
  - **Evidence mong đợi:** Metadata completeness report.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-43-01 | `components/*/*.prompt.md` (18 files) | FAIL | Mỗi prompt.md nêu purpose + when-to-use qua ví dụ, nhưng when-not-to-use chỉ có ở `MxContextualAppBar.prompt.md:22-27`; ~16/18 component thiếu when-not-to-use. |
| KIT-43-02 | `components/core/MxButton.d.ts:7-25`, `MxTextField.d.ts`, `components/surfaces/MxCard.d.ts`, tất cả `.prompt.md` | PASS | `.d.ts` type union hoá variant/size/props (slot props: actions/leading/avatar/children/label/helper/error); combos ghi rõ (`danger` composes with variant). |
| KIT-43-03 | `components/*/*.prompt.md`, `readme.md:55` | FAIL | State matrix per-component không có trong prompt.md (state matrix chỉ ở screen specs); interaction/theme mô tả ở mức readme, platform (RN) adaptation không ghi per component. |
| KIT-43-04 | `components/core/MxTextField.prompt.md:24`, `readme.md` | FAIL | Accessibility ghi tốt cho MxTextField/MxContextualAppBar/MxButton; content limits, localization và RTL không được ghi per component (RTL không xuất hiện ở đâu). |
| KIT-43-05 | `components/*/*.prompt.md`, `MxContextualAppBar.prompt.md:22-27` | FAIL | jsx example có ở mọi prompt.md; do/don't và edge-case chỉ hệ thống hoá cho MxContextualAppBar; đa số component thiếu don't + edge-case. |
| KIT-43-06 | `components/*/*.d.ts` `@startingPoint`, `_ds_manifest.json` sourcePath | FAIL | Source link có (@startingPoint + manifest.sourcePath); version, owner và deprecation status hoàn toàn vắng ở mọi component doc. |
| KIT-43-01 | components/**/*.prompt.md When-not-to-use sections | FIXED | Remediation — audit v5 fix loop. |
| KIT-43-03 | components/**/*.prompt.md States + RN adaptation | FIXED | Remediation — audit v5 fix loop. |
| KIT-43-04 | components/**/*.prompt.md content-limit + localization/RTL notes | FIXED | Remediation — audit v5 fix loop. |
| KIT-43-05 | components/**/*.prompt.md Do/Don't + edge cases | FIXED | Remediation — audit v5 fix loop. |
| KIT-43-06 | components/**/*.prompt.md version/owner/deprecation meta line | FIXED | Remediation — audit v5 fix loop. |

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
