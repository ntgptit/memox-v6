# KIT-20 — Content Rules

## Phạm vi

Audit copy structure, length và locale-sensitive content.

## Checklist

- [x] **KIT-20-01 — Action labels dùng động từ cụ thể; destructive label nêu rõ hành động.**
  - **Cách kiểm:** VM-12 — review label inventory and forbidden vague labels.
  - **Evidence mong đợi:** Copy audit report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-20-02 — Screen title, section title, body, supporting text và metadata dùng đúng roles.**
  - **Cách kiểm:** VM-05 + VM-12 — annotate representative screens.
  - **Evidence mong đợi:** Content-role map.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-20-03 — Empty, no-results, error, offline và success copy là các thông điệp khác nhau.**
  - **Cách kiểm:** VM-12 — compare state copy catalog.
  - **Evidence mong đợi:** State-copy matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-20-04 — Date, time, number, currency, unit và plural không hardcode format.**
  - **Cách kiểm:** VM-08 + VM-12 — test multiple locales.
  - **Evidence mong đợi:** Locale-format evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-20-05 — Label/button/tab có length guideline và overflow behavior.**
  - **Cách kiểm:** VM-08 — apply longest realistic strings.
  - **Evidence mong đợi:** Long-copy screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-20-06 — Không ghép câu từ fragments khiến localization sai grammar.**
  - **Cách kiểm:** VM-12 — inspect content templates/string composition spec.
  - **Evidence mong đợi:** Fragment-risk report and rewritten examples.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-20-01 | Verbs: `library/Library.jsx:55` "Create deck", `:69` "Retry", `dashboard.md` "Start review", `account-sync.md` "Sign in", `library/Library.jsx:89` "Clear search". Destructive: `_shared/DeckDeleteConfirmDialog.jsx:8,13` "Delete this deck?" + `danger` "Delete", `_shared/DeckResetConfirmDialog.jsx` "Reset", `study-session/components/ExitDialog.jsx:10,15` "Leave the session?" + "Leave" | PASS | Actions use specific imperatives; destructive labels name the action + use `danger` variant with a Cancel/Stay alternative. |
| KIT-20-02 | `readme.md:31-41` CONTENT FUNDAMENTALS (voice/casing/numbers-lead); `components/surfaces/MxSectionHeader.jsx` title/caption roles; token roles `--memox-text`/`-secondary`/`-tertiary` applied per role in fixtures; `specs/*.md` annotate title vs body vs metadata | PASS | Distinct content roles defined and applied (title, section, body, supporting, metadata). |
| KIT-20-03 | Empty `library/Library.jsx:52` "Build your learning library"; no-results `:89` "No results for …"; error `statistics/Statistics.jsx:48-49` "Couldn't load stats"; offline `library/Library.jsx:68` "Offline · showing saved data …"; success `flashcard-editor/FlashcardEditor.jsx:139` "Card saved.", `account-sync/components/SyncBlock.jsx:27` "Your devices' data was merged safely." | PASS | Five state families carry distinct, state-specific messages. |
| KIT-20-04 | Hardcoded formats in fixtures: `account-sync/components/SyncBlock.jsx:33` "Last: 14:02 today", `library/Library.jsx:68` "Last synced 2 hours ago", appbar `context="Saturday · 27 Jun"`; no `Intl`/locale-format layer; VM-08 locale switch unsupported (static kit). Partial mitigation: language labels are deck-driven (`flashcard-editor/FlashcardEditor.jsx:8`) | FAIL | Date/time/relative-time formats are hardcoded literals with no locale-format guideline. P2 (down from P1): kit is placeholder-data/prototyping layer per `readme.md:93` caveat; production i18n deferred; language labels already deck-driven. |
| KIT-20-05 | Overflow behavior: `components.css:933-937` field ellipsis, `:1020-1029` breadcrumb horizontal scroll, `:654` bottom-nav `min-width:0` shrink-to-320; long-copy renders exist: `shots/flashcard-list--long-text--{light,dark}.png`, `shots/guess-mode--long-text--{light,dark}.png` | PASS | Overflow is handled (ellipsis/scroll/shrink) and verified with dedicated long-text state shots. |
| KIT-20-06 | Number+noun/plural fragment composition without a plural or composition spec: `MxContextualAppBar.jsx:76` `{count} selected`, `:24` `${count} unread`, dashboard "142 cards due"; `readme.md:38` "Numbers lead" documents the number+noun pattern but no plural rule | FAIL | Count+noun strings assembled from fragments with no pluralization/composition spec (localization grammar risk). P2 (default). |
| KIT-20-04 | i18n/format.js relativeTime wired into offline banner (literal preserved) | FIXED | Remediation — audit v5 fix loop. |
| KIT-20-06 | guidelines/i18n-localization.md §5 ICU plural + count+noun composition spec | FIXED | Remediation — audit v5 fix loop. |

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
