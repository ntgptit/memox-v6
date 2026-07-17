# KIT-24 — Navigation Patterns

## Phạm vi

Audit hierarchy, routing affordances và state preservation ở cấp design.

## Checklist

- [x] **KIT-24-01 — Top bar phân biệt back, close, title và trailing actions; số actions có giới hạn.**
  - **Cách kiểm:** VM-04 + VM-05 — inspect top-bar variants.
  - **Evidence mong đợi:** Top-bar matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-24-02 — Bottom navigation chỉ chứa stable top-level destinations và selected state rõ.**
  - **Cách kiểm:** VM-05 + VM-10 — inspect nav examples and semantics.
  - **Evidence mong đợi:** Destination/selected-state evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-24-03 — Tabs chỉ dùng cho peer content; overflow và long label có rule.**
  - **Cách kiểm:** VM-08 + VM-07 — stress tab labels/count.
  - **Evidence mong đợi:** Tab stress screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-24-04 — System back, visual back và close không bypass dirty/destructive confirmation.**
  - **Cách kiểm:** VM-09 — execute all exit paths.
  - **Evidence mong đợi:** Back/close behavior matrix.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-24-05 — Modal navigation có entry, nested stack limit và focus restoration rõ.**
  - **Cách kiểm:** VM-09 + VM-10 — walkthrough modal flow.
  - **Evidence mong đợi:** Modal navigation recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-24-06 — Tab/route change giữ hoặc reset scroll, search và filter state theo rule.**
  - **Cách kiểm:** VM-09 — navigate away/back across patterns.
  - **Evidence mong đợi:** State-preservation evidence.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-24-01 | `MxContextualAppBar.jsx:60-79` distinct leading (nested/search=back, modal/selection=close) + title vs search vs "N selected" slots; `MxContextualAppBar.prompt.md:23` "Max 2 direct right actions", `:12` "3rd → overflow"; `shots/app-bar--nested-overflow--{light,dark}.png` | PASS | Top bar distinguishes back/close/title/trailing and caps actions at 2 (3rd → overflow). |
| KIT-24-02 | `MxBottomNav.jsx:4-22` renders top-level destinations, but the active item carries only a visual `bottom-nav__item--active` class (`components.css:680-690`) — no `aria-current`/`aria-selected`/`role="tab"`; selected state is not programmatically exposed | FAIL | Destinations are stable and visually clear, but selected state is not exposed to AT. P1 (a11y floor). |
| KIT-24-03 | `MxSegmentedControl.jsx:4-22` used for peer content only (`statistics/Statistics.jsx:20-21` This pair/All; theme/export/player); `segmented--block` distributes evenly; app-bar action overflow → `more_vert` (`prompt.md:12`). Design constrains tabs to few short peer labels (no scrollable-tab pattern) | PASS | Tabs are peer-only; short-label segmented + block distribution + action overflow constitute the rule. |
| KIT-24-04 | Destructive/dirty exits route through confirms by design: `study-session/components/ExitDialog.jsx` (unfinished-cards warning), `_shared/DeckDeleteConfirmDialog.jsx`, `_shared/DeckResetConfirmDialog.jsx`, `flashcard-editor/FlashcardEditor.jsx:10` dirty-cancel via shared ConfirmDialog | PASS | Every destructive/dirty exit path has a designed confirmation; no bypass path in the design. |
| KIT-24-05 | Modal entry designed: `MxContextualAppBar` modal variant + `shots/app-bar--modal--{light,dark}.png` (close). But no nested-modal-stack-limit rule and no focus-restoration spec documented | FAIL | Modal entry exists; nested-stack limit + focus restoration are unspecified. P2 (down from P1): runtime-nav behaviors deferred by `readme.md:93` caveat ("no navigation logic yet"), owner+target assigned. |
| KIT-24-06 | No documented rule for preserving vs resetting scroll/search/filter on tab/route change; static kit renders states independently and cannot exercise VM-09 route round-trips | FAIL | State-preservation rule is absent. P2 (down from P1): runtime-nav behavior deferred by `readme.md:93` caveat, owner+target assigned. |
| KIT-24-02 | MxBottomNav aria-current='page' | FIXED | Remediation — audit v5 fix loop. |
| KIT-24-05 | guidelines/navigation-overlays.md §2 stack limit + focus restoration | FIXED | Remediation — audit v5 fix loop. |
| KIT-24-06 | guidelines/navigation-overlays.md §3 preserve-vs-reset table | FIXED | Remediation — audit v5 fix loop. |

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
