# Study Statistics business flows

Study Statistics là read-only projection từ committed Sessions, Attempts, Progress và Streak. Nó không sở hữu dữ liệu nguồn hoặc scheduling decisions.

## Invariants

- Metrics chỉ derive từ committed/versioned records và formula version rõ.
- Read/scope switch không mutate source objects.
- Attempt/Session contribution không double-count.
- Parent Deck scope aggregate descendant Cards đúng một lần.
- Reset Progress không xóa historical metrics; reset boundary được biểu diễn khi cần.
- Time range/timezone/rounding deterministic và localized.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [build-study-statistics.md](./build-study-statistics.md) | Aggregate committed activity thành metric projection | Đã có |
| [view-study-statistics.md](./view-study-statistics.md) | Hiển thị summary, retention, heatmap và trends | Đã có |
| [switch-statistics-scope.md](./switch-statistics-scope.md) | All/Deck/time-range selection và stale-response guard | Đã có |
| [handle-insufficient-statistics.md](./handle-insufficient-statistics.md) | Empty/insufficient-data thresholds và recovery | Đã có |
| [rebuild-statistics-projection.md](./rebuild-statistics-projection.md) | Reset/sync/restore reconciliation và retry | Đã có |

## Cross-object contracts

- Đọc history contract từ `learning-progress/inspect-progress-history.md`.
- Đọc finalized summaries từ Study Session và day records từ Study Streak.
- Deck cung cấp hierarchy scope; Statistics không thay đổi Deck.
- Today Dashboard chỉ consume compact summary, không tự tính metric.

## Canonical state coverage

- Loaded; scope switch; insufficient; loading; error.
- Global/Leaf/Parent/time ranges; reset boundary; late sync/rebuild.
- Large counts, long labels, large font, narrow device, light/dark.
