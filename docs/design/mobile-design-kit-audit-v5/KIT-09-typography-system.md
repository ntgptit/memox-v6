# KIT-09 — Typography System

## Phạm vi

Audit type roles, metrics và scaling; raw primitive values thuộc KIT-04.

## Checklist

- [x] **KIT-09-01 — Mỗi type role có purpose, size, weight, line-height và letter-spacing rõ.**
  - **Cách kiểm:** VM-12 + VM-01 — đối chiếu guideline với style/token export.
  - **Evidence mong đợi:** Type-role table có đầy đủ properties và usage.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-09-02 — Không có hai roles gần như giống nhau nhưng khác tên.**
  - **Cách kiểm:** VM-11 — so vector properties và usage descriptions.
  - **Evidence mong đợi:** Near-duplicate role report và quyết định merge.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-09-03 — Heading, body, label, caption tạo hierarchy ổn định trên screen mẫu.**
  - **Cách kiểm:** VM-05 — đặt screen samples cạnh nhau và kiểm visual priority.
  - **Evidence mong đợi:** Annotated screenshots chỉ rõ role trên từng vùng.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-09-04 — Font fallback hỗ trợ Vietnamese, CJK và RTL theo scope, không cắt glyph.**
  - **Cách kiểm:** VM-08 — thay sample text và inspect baseline/diacritics.
  - **Evidence mong đợi:** Screenshots từng script và danh sách fallback fonts.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-09-05 — Text scaling tới 200% không cắt nội dung hoặc khóa hành động chính.**
  - **Cách kiểm:** VM-08 + VM-07 — tăng text size trên representative components/patterns.
  - **Evidence mong đợi:** Before/after evidence và issue list.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-09-06 — Wrapping, truncation và max-lines được quy định theo component/content importance.**
  - **Cách kiểm:** VM-12 + VM-08 — test chuỗi dài và đối chiếu content rules.
  - **Evidence mong đợi:** Matrix component × wrapping/truncation behavior.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-09-01 | tokens/typography.css:20-48; guidelines/type-scale.html:17-24; components.css:123-130,295-298 | PASS | Token size/weight/line-height/letter-spacing đầy đủ; type-scale.html liệt kê role (Display…Overline) kèm size+weight+letter-spacing; component bind role. Lưu ý: line-height theo default toàn cục (`--memox-line-height-normal` trên `.app`), không phải cột riêng mỗi role. |
| KIT-09-02 | tokens/typography.css:20-28; guidelines/type-scale.html | PASS | 9 size phân biệt, mỗi role ánh xạ 1:1 tới size/weight riêng; xs12 vs sm13 phân biệt bằng caps letter-spacing/uppercase (overline vs caption). Không có near-duplicate. |
| KIT-09-03 | ui_kits/memox-app/shots/dashboard--loaded--light.png/--dark.png; components.css:290-298,116-130 | PASS | Shot màn hình thật + bind role component cho ưu tiên heading > body > caption ổn định. |
| KIT-09-04 | tokens/typography.css:15-16; grep high-contrast/script docs = 0 | FAIL | Stack Plus Jakarta Sans + system fallback phủ Vietnamese, nhưng không có danh sách fallback theo script (CJK/RTL) và không có screenshot từng script; scope script chưa được tài liệu hóa. |
| KIT-09-05 | tokens/typography.css:20-28 (px cố định); tokens/component.css (chiều cao control cố định); không có before/after 200% | FAIL | Không có evidence text-scaling 200%; kit dùng px cố định + control chiều cao cố định (chip 34/appbar 56/nav 80); chưa kiểm chứng (production map sang RN scalable type) — verification gap. |
| KIT-09-06 | components.css:118-121,128-129,1020-1059 (nowrap+ellipsis cục bộ) | FAIL | Có truncation cục bộ trong CSS (cappbar title/context nowrap+ellipsis, breadcrumb nowrap) nhưng không có matrix wrapping/truncation/max-lines theo component/content importance. |
| KIT-09-04 | i18n per-script fallback documented; per-script rendered shots pending CI (CDN blocked locally) | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-09-05 | shoot.mjs renders font-scale up to 1.5 + i18n 200% guidance; committed 200% shots pending CI (CDN blocked locally) | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-09-06 | guidelines/component-constraints-matrix.md §1 text-wrap/truncation matrix | FIXED | Remediation — audit v5 fix loop. |
| KIT-09-04 | tokens/typography.css:18-33 (--memox-font-cjk + --memox-font-vietnamese fallback stacks); shots/languages--scripts--{light,dark}.png (vi + ko + ja + zh rendered qua --memox-font-cjk); shots/flashcard-editor--keyboard-open (Korean), flashcard-editor additional-translation (Vietnamese) | FIXED | Per-script fallback stack đã khai báo + wire; Vietnamese diacritics + CJK (Korean/Japanese/Chinese) + mixed-script render không tofu. Xem governance/coverage-report.md. |
| KIT-09-05 | tool/ui_kit_shots/shoot.mjs FONT_SCALES gồm 2.0; full matrix 320-430px × 100-200% sạch sau khi wrap confirm-dialog action row (components.css .mx-dialog-actions + kit-helpers.jsx Dialog); evidence/200pct-dialog-fixed--*.png | FIXED | 200% text scaling: overflow duy nhất (nút dialog trên 320px) đã fix; không cắt nội dung, không khóa hành động chính. Xem governance/coverage-report.md. |

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
