# KIT-30 — Loading, Empty, Error và Offline

## Phạm vi

Audit state surfaces cấp screen/section.

## Checklist

- [x] **KIT-30-01 — Initial loading không để blank screen và giữ layout shift thấp.**
  - **Cách kiểm:** VM-05 + VM-09 — observe initial load with throttled prototype.
  - **Evidence mong đợi:** Loading recording/screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-30-02 — Incremental loading/refresh giữ content hiện có và có retry tại đúng vị trí.**
  - **Cách kiểm:** VM-09 — force pagination/refresh failure.
  - **Evidence mong đợi:** Incremental-state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-30-03 — First-use empty có explanation và next action phù hợp.**
  - **Cách kiểm:** VM-05 + VM-12 — inspect empty templates.
  - **Evidence mong đợi:** Empty-state copy/action evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-30-04 — No-results nêu query/filter context và có clear/reset path.**
  - **Cách kiểm:** VM-09 — trigger unmatched query/filter.
  - **Evidence mong đợi:** No-results recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-30-05 — Error không lộ technical detail, có retry hoặc safe alternative path.**
  - **Cách kiểm:** VM-09 + VM-12 — force repository/system error in prototype spec.
  - **Evidence mong đợi:** Error-state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-30-06 — Offline khác stale/cached data và hiển thị freshness khi cần.**
  - **Cách kiểm:** VM-05 + VM-12 — compare offline/stale variants.
  - **Evidence mong đợi:** Offline/stale state matrix.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-30-01 | `_features/library/Library.jsx:39-45`; `_features/flashcard-list/FlashcardList.jsx:37-43`; `_features/search/Search.jsx:47-56`; `shots/library--loading--light.png` | PASS | Loading dùng skeleton phản chiếu layout cuối (chip + card rows cùng shape/height) → không blank, layout shift thấp. Có ở library/flashcard-list/search/dashboard/statistics/subdeck. |
| KIT-30-02 | `_features/library/Library.jsx:63-74`; `_features/flashcard-list/FlashcardList.jsx:61-73`; `shots/flashcard-list--offline--light.png` | PASS | Refresh-failure (offline) giữ nguyên content hiện có + Retry inline trong banner (đúng vị trí top cho whole-screen refresh). Kit không có infinite-scroll pagination nên đây là case incremental áp dụng. Initial-load error mới thay full-screen (phân biệt đúng). |
| KIT-30-03 | `kit-helpers.jsx:41-53`; `_features/library/Library.jsx:49-59`; `_features/flashcard-list/FlashcardList.jsx:47-57`; `shots/library--empty--light.png` | PASS | First-use empty có icon + title giải thích + text + primary next action (Create deck / Add card + Import). Đủ ở library/flashcard-list/subdeck/languages. |
| KIT-30-04 | `_features/search/Search.jsx:59-66`; `_features/library/Library.jsx:88-89`; `_features/flashcard-list/FlashcardList.jsx:92-93` | PASS | No-results nêu query context ("Nothing matched 'xyz'", "No results for 'business Korean'") và có clear/reset (Clear search + X app bar); copy nhắc "clear your filters". |
| KIT-30-05 | `_features/flashcard-list/FlashcardList.jsx:74-81`; `_features/import/Import.jsx:35-42`; `_features/export/Export.jsx:24-31`; `_features/study-session/components/ResumeErrorState.jsx` | PASS | Error dùng copy người đọc được (không stack trace/mã lỗi), có Retry hoặc safe path (Back to deck). "row 78" là context hữu ích, không phải technical detail nghiêm trọng. |
| KIT-30-06 | `_features/library/Library.jsx:63-74`; `_features/flashcard-list/FlashcardList.jsx:61-73`; `_features/account-sync/components/SyncBlock.jsx:16-36`; `shots/{flashcard-list--offline,account-sync--conflict}--light.png` | PASS | Offline (cloud_off, warning tone) khác normal/stale và hiển thị freshness ("Last synced 2 hours ago"); account-sync phân biệt offline / syncing / synced ("Last: 14:02") / conflict merged. |

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
