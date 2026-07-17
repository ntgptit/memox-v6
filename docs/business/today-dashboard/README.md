# Today Dashboard business flows

Today Dashboard là orchestration/read projection giúp user tiếp tục hành động học phù hợp nhất. Nó không sở hữu Deck, Due, Goal, Streak hoặc Session data.

## Invariants

- Primary objective duy nhất: resume/start learning từ current state.
- Dashboard chỉ hiển thị committed/current projections; không tự tính SRS/Goal/Streak.
- Paused Session được ưu tiên hơn Start new review khi phù hợp.
- Empty Library và caught-up là hai states khác nhau.
- First-run `Not now` không tự mở onboarding lại.
- Dashboard actions revalidate target/state trước navigation.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [load-today-dashboard.md](./load-today-dashboard.md) | Compose Due, Goal, Streak, Session và Deck summaries | Đã có |
| [continue-session-from-today.md](./continue-session-from-today.md) | Resume CTA, failure và return | Đã có |
| [start-review-from-today.md](./start-review-from-today.md) | Due scope handoff tới Mode/Session | Đã có |
| [handle-caught-up-today.md](./handle-caught-up-today.md) | Zero due nhưng Library có content | Đã có |
| [handle-empty-library-today.md](./handle-empty-library-today.md) | Fresh/old user empty states và Create/Import | Đã có |
| [manage-today-create-actions.md](./manage-today-create-actions.md) | Add Card/Create Deck/Import action sheet | Đã có |
| [refresh-today-projections.md](./refresh-today-projections.md) | Foreground/pull/success refresh và stale guards | Đã có |

## Cross-object contracts

- Due/new/relearn counts từ Learning Progress.
- Paused session từ Study Session; Goal/Streak từ respective projections.
- Recent Deck cards từ Deck; create/add/import actions handoff owning flows.
- Dashboard không persist business records ngoài presentation/recent UI policy.

## Canonical state coverage

- Loaded; not-studied; goal-met; streak-reset; caught-up.
- Create sheet; empty; empty-after-onboarding-skip; loading/error/offline.
- Long greeting/deck names/counts, large font, narrow device, light/dark.
