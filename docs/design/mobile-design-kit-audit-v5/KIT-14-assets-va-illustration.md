# KIT-14 — Assets và Illustration

## Phạm vi

Audit asset quality, ratio, fallback và brand handling.

## Checklist

- [x] **KIT-14-01 — Mỗi asset có source, format, export scale và owner rõ.**
  - **Cách kiểm:** VM-14 — inspect asset catalog/export settings.
  - **Evidence mong đợi:** Asset manifest.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-14-02 — Raster đủ resolution cho density cao và không bị upscale.**
  - **Cách kiểm:** VM-14 — compare intrinsic dimensions với usage dimensions.
  - **Evidence mong đợi:** Resolution audit report.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-14-03 — Aspect ratio, crop focal point và safe zone được định nghĩa cho media types.**
  - **Cách kiểm:** VM-14 + VM-07 — resize representative media.
  - **Evidence mong đợi:** Ratio/crop matrix và screenshots.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-14-04 — Placeholder, loading và broken-asset fallback giữ cùng layout ratio.**
  - **Cách kiểm:** VM-05 — swap asset states.
  - **Evidence mong đợi:** State comparison evidence.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-14-05 — Logo/brand asset có clear space, minimum size và dark-background variant.**
  - **Cách kiểm:** VM-14 + VM-12 — inspect brand guide/examples.
  - **Evidence mong đợi:** Brand asset spec and examples.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-14-06 — Asset không chứa text cố định khi nội dung cần localization.**
  - **Cách kiểm:** VM-14 + VM-08 — scan images/illustrations and locale samples.
  - **Evidence mong đợi:** List of text-in-asset violations or approved exceptions.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-14-01 | fonts/PlusJakartaSans[wght].ttf; tokens/typography.css @font-face; readme.md:82 (fonts), readme.md:63 (icons = Material Symbols Rounded CDN) | PASS | Asset thiết kế duy nhất là variable font Plus Jakarta Sans (nguồn, format TTF, owner rõ); icon lấy từ Material Symbols CDN. Kit không có raster/illustration asset khác nên không có mục chưa được catalog. |
| KIT-14-02 | readme.md:15 (không dùng photographic imagery/patterns/gradients); MxAvatar.jsx (image `src`); components.css .avatar img object-fit cover (897-900) | PASS | Kit không ship raster imagery; icon là vector font; ảnh duy nhất là avatar người dùng do runtime cấp. Không có bitmap nội bộ để upscale. |
| KIT-14-03 | components.css .avatar (881-899) width/height = avatar token, border-radius full, overflow hidden, `object-fit: cover`; component.css avatar sm32/md44/lg64 | PASS | Media type duy nhất là avatar 1:1 (crop center qua object-fit cover, safe zone = ô tròn cố định). Kit không có cover/free-form media. |
| KIT-14-04 | MxAvatar.jsx (initials fallback khi thiếu `src`); components.css .avatar ô cố định 1:1 (884-895); .spinner loading (1085-1098) | PASS | Fallback initials và ô avatar cố định giữ nguyên layout ratio ở mọi state. Lưu ý: broken URL chưa có onError để swap sang initials (ô vẫn giữ ratio). |
| KIT-14-05 | readme.md:91 (caveat: "No brand logo / app icon asset was provided"); readme.md:67 (wordmark set bằng Plus Jakarta Sans Extrabold) | FAIL | Không có logo/brand asset; chỉ có wordmark bằng type, chưa định nghĩa clear space, minimum size, dark-background variant. Đây là known caveat của kit. |
| KIT-14-06 | readme.md:66 (no emoji; Unicode chỉ cho content thật); icon = font glyph không chứa text; không có illustration | PASS | Không có asset nào chứa text cố định cần localization; wordmark "MemoX" là tên thương hiệu (không dịch). |
| KIT-14-05 | assets/memox-wordmark(.dark).svg + asset-export-spec wordmark spec (bespoke icon still noted pending) | FIXED | Remediation — audit v5 fix loop. |

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
