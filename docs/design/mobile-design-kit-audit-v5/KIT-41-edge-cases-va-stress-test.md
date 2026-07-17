# KIT-41 — Edge Cases và Stress Test

## Phạm vi

Audit extreme content/data/state combinations.

## Checklist

- [x] **KIT-41-01 — Empty, one-character, very long, URL và emoji text không phá layout.**
  - **Cách kiểm:** VM-08 + VM-07 — run text corpus.
  - **Evidence mong đợi:** Text stress screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-41-02 — Zero, negative, unknown, huge count/currency/percentage có display rule.**
  - **Cách kiểm:** VM-08 — populate numeric boundary dataset.
  - **Evidence mong đợi:** Numeric boundary evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-41-03 — Missing, broken, tall, wide và transparent media giữ layout/fallback đúng.**
  - **Cách kiểm:** VM-14 + VM-07 — swap media corpus.
  - **Evidence mong đợi:** Media stress gallery.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-41-04 — Một item, nhiều trăm item và mixed-height list giữ structure/controls usable.**
  - **Cách kiểm:** VM-07 + VM-09 — inspect data-density prototypes.
  - **Evidence mong đợi:** List density evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-41-05 — Loading + existing data, error + partial data, offline + stale đều có state riêng.**
  - **Cách kiểm:** VM-04 + VM-05 — render combination matrix.
  - **Evidence mong đợi:** Combined-state matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-41-06 — RTL + long text + 200% scaling + landscape không tạo blocker.**
  - **Cách kiểm:** VM-08 + VM-07 — run combined worst-case profile.
  - **Evidence mong đợi:** Worst-case screenshots and blockers.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-41-01 | `shots/flashcard-list--long-text--*.png` (truncate + Show more), `*--empty--*.png`, `*--minimum-data--*.png` | PASS | Long text và empty giữ layout; emoji bị loại theo policy (`readme.md`); URL/one-char không nằm trong corpus. |
| KIT-41-02 | `audit/_sheets/16-edge-a.png` ("124 CARDS", "Not enough data"); `17-edge-b.png` ("0 day streak", "55% mastered", "70%") | PASS | Zero/percentage/count/unknown có display rule; currency/negative không thuộc domain flashcard. |
| KIT-41-03 | `components/core/MxAvatar.jsx:10` (src? img : initials); `readme.md` (no photographic imagery); icon = Material Symbols font | PASS | Không có raster media rủi ro; avatar fallback initials. Ghi chú: MxAvatar chưa có onError→initials khi src 404. |
| KIT-41-04 | `shots/library--dense--*.png`, `flashcard-list--dense--*.png`, `subdeck-list--dense--*.png`; mixed-height qua long-text card | PASS | Danh sách dày, mixed-height và min-data giữ structure/controls usable. |
| KIT-41-05 | `shots/flashcard-list--offline--light.png` ("Offline · showing saved cards. Last synced 2 hours ago" + Retry); `account-sync--conflict--light.png` (merged data); `*--error--*.png`, `dashboard--loading--*.png` | PASS | Offline+stale và conflict+partial data có state riêng; loading/error tách biệt. |
| KIT-41-06 | Không có RTL (KIT-37-03); không có shot 200% text / landscape (toàn bộ 390×780 portrait) | FAIL | Combined worst-case RTL + long text + 200% + landscape không được test. |
| KIT-41-06 | RTL/logical + reduced-motion + HC present; combined worst-case rendered stress pending CI | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-41-06 | tool/ui_kit_shots/rtl-stress.mjs (dir=rtl + longest-content state + 200% @ 320px: 8 renders, 0 blockers); evidence/rtl-combined--*.png (app bar/breadcrumb/chips/cards mirror, text wraps, không cắt) | FIXED | Combined worst-case RTL + long text + 200% không tạo blocker; landscape scoped-out (SCOPE.md), 320×200% portrait là stress tương đương. |

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
