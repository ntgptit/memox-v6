# Study Streak business flows

Study Streak là projection theo local day từ finalized Study activity. Nó khác Daily Goal: Goal đo target trong ngày; Streak đo chuỗi ngày có activity hợp lệ.

## Invariants

- Một local day đóng góp tối đa một streak-qualified day.
- Chỉ finalized/qualified Study activity theo policy mới đánh dấu ngày.
- Retry Finalize/Sync không double-count day.
- Missed day break/reset behavior deterministic theo local-day/timezone contract.
- Timezone/DST không tạo ngày giả hoặc hai contribution cho một event.
- Streak read model không mutate Sessions/Progress.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [record-streak-day.md](./record-streak-day.md) | Mark qualified local day idempotently | Đã có |
| [calculate-current-streak.md](./calculate-current-streak.md) | Tính current/longest streak từ day records | Đã có |
| [handle-streak-break.md](./handle-streak-break.md) | Missed-day transition và feedback | Đã có |
| [handle-streak-boundary.md](./handle-streak-boundary.md) | Midnight/timezone/DST rollover | Đã có |
| [reconcile-streak-history.md](./reconcile-streak-history.md) | Late sync/restore và projection rebuild | Đã có |

## Cross-object contracts

- Nhận qualified completion event từ finalized Study Session.
- Dùng local-day contract của Study Goal nhưng không phụ thuộc Goal enabled/met.
- Trả current/longest/reset state cho Today Dashboard và Study Statistics.
- Backup/Sync transport day records với stable identity.

## Canonical state coverage

- Zero/first/current/longest streak; same-day repeat.
- Streak break/reset; multi-day gap; timezone/DST/manual clock.
- Late sync/rebuild/error; large counts, long localized copy, light/dark presentation.
