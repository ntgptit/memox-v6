# Navigation and entry contract

Navigation là supporting interaction contract, không sở hữu business data hoặc domain invariants. V1 Tier 1 là Web và Android; route semantics phải giống nhau, còn URL/back-stack presentation theo platform.

## Product decisions

- Tier 1: responsive Web và Android, bao gồm phone/tablet/landscape; Web phải hỗ trợ keyboard, browser Back/Forward, refresh và deep link.
- iOS/Windows/macOS/Linux là roadmap; không dùng yêu cầu riêng của các platform đó để chặn v1, nhưng route ids/domain inputs không được gắn Android-only.
- Locale v1: English và Vietnamese. Route ids/URL segments không localized. RTL-ready nhưng runtime RTL deferred.

## Canonical destinations

| Route id | Required identity | Missing/invalid recovery |
| --- | --- | --- |
| `today` | None | App home |
| `library` | Optional language-pair id | Prompt/select active pair khi thiếu |
| `deck` | Deck id | Library + not-found feedback |
| `card` | Card id | Owning Deck/Library + not-found feedback |
| `studySetup` | Deck/scope id | Revalidate eligibility; never auto-start |
| `studySession` | Session id | Resume/result/unavailable branch by status |
| `studyResult` | Completed session id | Resume-finalize if finalizing; unavailable if missing |
| `search` | Optional query/filter | Blank query contract when absent |
| `settings` | Optional section id | Settings root for unknown section |
| `backup` | None | Backup root |
| `account` | None | Signed-out/signed-in state, no forced auth for local data |

## First launch and guards

> Decision (ADR-009 / CF-16): first launch uses the **soft-onboarding** model. A fresh user is
> offered onboarding (create/import first content) but may choose **"Not now"** and land on an
> empty Today (a first-class no-content state — see `../today-dashboard/handle-empty-library-today.md`
> and `../deck/create-deck.md` §4). The Language-Pair prerequisite guards *content creation* (you
> cannot build a Deck/Library without a pair), not reaching Today.

1. Bootstrap local store and preferences.
2. Fresh user with no content: show onboarding (create/import). "Not now" opens an empty Today.
   Creating a Deck requires a Language Pair, so the create-content path routes to language-pair
   creation first when none exists; Back/refresh may not bypass this prerequisite into an invalid Library.
3. When at least one pair exists but none selected, route to selection.
4. Otherwise open Today (empty Today is valid for a no-content user). Active/paused session is
   surfaced as Continue but never auto-resumed without user action.
5. Account sign-in is not a global guard; local-first routes remain usable signed out/offline.

Feature guards re-read owning business state: Deck type/eligibility before Study, due state before Due Review, session status before Resume, backup compatibility before Restore. Guards return typed recovery destinations and never silently create/mutate data.

## Web contract

- Every canonical destination has a refresh-safe URL encoding only stable ids/non-sensitive filters.
- Browser Back/Forward restores prior route and safe view state; it must not repeat create/delete/start/answer/finalize commands.
- Opening a deep link in a new tab bootstraps prerequisites, then resumes intended destination or shows explicit inaccessible/not-found state.
- Unsaved form/session exit uses the owning discard/exit contract; browser refresh/crash recovery uses persisted draft/checkpoint where specified.

## Android contract

- System Back follows the same safe hierarchy as in-app Back and invokes owning discard/exit confirmation.
- Process death/recreation resolves pending command identity before enabling Retry.
- App links use the same route ids and prerequisite guards as Web deep links.

## Acceptance criteria

- Fresh install → Language Pair → Today/Library is deterministic on Web refresh and Android process recreation.
- URL/system Back never repeats a mutation or loses a committed Study checkpoint.
- Deleted/moved Deck/Card and completed/finalizing Session follow route-specific recovery above without loops.
- Signed-out/offline users can access all local-first routes except explicitly cloud-only Account/Backup provider actions.
- Route tests cover every destination × valid/missing identity × prerequisite/offline state for Web and Android.
