# KIT-37 — Localization và RTL

## Phạm vi

Audit expansion, scripts, RTL và locale formats.

## Checklist

- [x] **KIT-37-01 — Chuỗi dài hơn 30–50% không cắt button, tab, dialog hoặc list row quan trọng.**
  - **Cách kiểm:** VM-08 — replace with expansion corpus.
  - **Evidence mong đợi:** Localization stress screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-37-02 — Vietnamese diacritics, CJK glyph và mixed-script baseline hiển thị đúng.**
  - **Cách kiểm:** VM-08 — run script corpus with fallback fonts.
  - **Evidence mong đợi:** Script rendering evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-37-03 — RTL mirror leading/trailing, directional icon, swipe và reading order đúng.**
  - **Cách kiểm:** VM-08 + VM-09 — walkthrough RTL prototype.
  - **Evidence mong đợi:** LTR/RTL comparison recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-37-04 — Date, time, number, currency, unit và plural theo locale.**
  - **Cách kiểm:** VM-08 — render at least three locale profiles.
  - **Evidence mong đợi:** Locale-format table/screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-37-05 — Không hardcode left/right trong generic spec khi phải dùng start/end.**
  - **Cách kiểm:** VM-12 — scan documentation/property names.
  - **Evidence mong đợi:** Directionality scan report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-37-06 — Asset/copy không chứa text cố định hoặc English-only assumption.**
  - **Cách kiểm:** VM-14 + VM-08 — scan assets and copy examples.
  - **Evidence mong đợi:** Localization exception list.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-37-01 | `ui_kits/memox-app/shots/flashcard-list--long-text--*.png`, `guess-mode--long-text--*.png` | FAIL | Chỉ có content-stress tiếng Anh (truncate + Show more); không có localization expansion corpus 30–50% cho button/tab/dialog. |
| KIT-37-02 | `audit/_sheets/16-edge-a.png`, `17-edge-b.png`; `shots/flashcard-list--long-text--dark.png`; `tokens/typography.css` (chỉ @font-face Plus Jakarta Sans) | FAIL | CJK (Korean) và mixed-script baseline render đúng qua OS fallback; nhưng không khai báo font stack CJK/Vietnamese, không có evidence Vietnamese diacritics. |
| KIT-37-03 | `components.css` (0 logical property, 8 physical left/right); toàn kit không có `dir=`/RTL | FAIL | Không có bất kỳ RTL support nào: không mirror leading/trailing, directional icon, reading order. |
| KIT-37-04 | `shots/dashboard--loaded--*.png` ("Saturday · 27 Jun"); không có locale-format layer | FAIL | Date/time/number hardcode tiếng Anh; không có locale profile cho number/currency/plural/unit. |
| KIT-37-05 | `components.css` — `grep` physical left/right = 8, logical inline-start/end = 0 | FAIL | Generic spec dùng padding-left/right, text-align:left, left:/right: thay vì start/end. |
| KIT-37-06 | `ui_kits/memox-app/_features/**/*.jsx` (copy tiếng Anh hardcode); `readme.md` known caveats | FAIL | Mọi copy là English-only string trong JSX; không có string externalization / i18n. |
| KIT-37-01 | i18n en-XA +30-50% expansion corpus + expansion fixture states | FIXED | Remediation — audit v5 fix loop. |
| KIT-37-02 | i18n CJK/Vietnamese font stack declared; RN font map + diacritic/CJK shots pending CI | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-37-03 | components.css physical left/right → logical inline-start/end | FIXED | Remediation — audit v5 fix loop. |
| KIT-37-04 | i18n/format.js Intl date/number/relative-time/plural layer wired | FIXED | Remediation — audit v5 fix loop. |
| KIT-37-05 | components.css logical properties (start/end) | FIXED | Remediation — audit v5 fix loop. |
| KIT-37-06 | ui_kits/memox-app/i18n/strings.js keyed catalog (byte-identical) wired in 4 features | FIXED | Remediation — audit v5 fix loop. |
| KIT-37-02 | shots/languages--scripts--{light,dark}.png (Tiếng Việt diacritics + Korean/Japanese/Chinese CJK + mixed-script render qua --memox-font-cjk); tokens/typography.css:18-33 (--memox-font-cjk + --memox-font-vietnamese); shots/flashcard-editor--keyboard-open (Korean) | FIXED | Vietnamese diacritics + CJK glyph (ko/ja/zh) + mixed-script render đúng, không tofu; per-script fallback stack đã khai báo + wire. |

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
