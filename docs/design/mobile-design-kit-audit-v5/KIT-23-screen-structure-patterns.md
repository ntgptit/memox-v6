# KIT-23 — Screen Structure Patterns

## Phạm vi

Audit cấu trúc generic của các loại screen.

## Checklist

- [x] **KIT-23-01 — List pattern có header, controls, list region và empty/loading/error variants.**
  - **Cách kiểm:** VM-04 + VM-12 — inspect list template/state matrix.
  - **Evidence mong đợi:** List pattern coverage.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-23-02 — Detail pattern có title, content hierarchy, actions, not-found và safe back.**
  - **Cách kiểm:** VM-09 + VM-12 — walkthrough detail template.
  - **Evidence mong đợi:** Detail flow/state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-23-03 — Form/editor pattern có field order, validation, keyboard, dirty-close và submit states.**
  - **Cách kiểm:** VM-09 — run create/edit flow.
  - **Evidence mong đợi:** Form/editor flow recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-23-04 — Dashboard pattern ưu tiên next action và không có quá nhiều competing cards.**
  - **Cách kiểm:** VM-05 — hierarchy review with count of primary surfaces/actions.
  - **Evidence mong đợi:** Annotated dashboard template.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-23-05 — Settings pattern phân biệt navigation row, toggle, value row và destructive section.**
  - **Cách kiểm:** VM-04 + VM-05 — inspect settings template.
  - **Evidence mong đợi:** Settings row matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-23-06 — Search/selection pattern phân biệt normal, searching, no-results và selection modes.**
  - **Cách kiểm:** VM-09 — transition between modes.
  - **Evidence mong đợi:** Mode transition evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-23-01 | `specs/library.md` (List archetype) states loaded/dense/empty/loading/offline/search-no-results/filter; `specs/subdeck-list.md` states loaded/empty/loading/error/offline (empty+loading+error all present); header+search-dock controls + `MxList` region | PASS | List pattern covers header, controls, list region and empty/loading/error variants. |
| KIT-23-02 | `specs/account-sync.md` (Detail) has nested app bar back (safe back) + title/hierarchy/actions, states signed-out/in/syncing/conflict/offline; `specs/subdeck-list.md` has error/empty. But grep across `_features`/`specs`: no `not-found`/deleted-entity/404 detail variant exists | FAIL | Detail pattern lacks a not-found / deleted-entity state. P1 (default): title/hierarchy/actions/safe-back present, only not-found missing. |
| KIT-23-03 | `specs/flashcard-editor.md` (Form) states validation + submitting/submit-error/submit-success; `FlashcardEditor.jsx:1-11` field order + progressive disclosure; `components/Field.jsx:11-14,28-31` keyboard intent (data-input-mode/enter-key-hint/autofocus); `FlashcardEditor.jsx:10` dirty-cancel via shared ConfirmDialog | PASS | Form pattern has field order, validation, keyboard intent, dirty-close and submit lifecycle states. |
| KIT-23-04 | `specs/dashboard.md` (Dashboard) Primary CTA "Start review" (single next action); composition surfaces StreakCard/GoalCard/TodaySummary; `mobile-ui-construction-contract.md:72-78` hierarchy rules (primary weight highest, not every section a card) | PASS | Dashboard prioritises the next action and avoids competing cards. |
| KIT-23-05 | `specs/settings.md` component map `window.ListRow` (nav rows) + `MxSwitch` (toggles) + `value-picker` state (value rows); destructive section handled in `specs/deck-settings.md` action-sheet/reset-confirm/delete-confirm | PASS | Settings pattern distinguishes navigation row, toggle, value row and destructive section. |
| KIT-23-06 | `specs/search.md` states empty-recent/results/filtered/no-results/loading (normal vs searching vs no-results); `specs/library.md` states search-active/search-results/search-no-results + `selection` mode; `MxContextualAppBar` search/selection variants | PASS | Search/selection modes (normal, searching, no-results, selection) are distinct states. |
| KIT-23-02 | subdeck-list + flashcard-list not-found (deleted-entity) state | FIXED | Remediation — audit v5 fix loop. |

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
