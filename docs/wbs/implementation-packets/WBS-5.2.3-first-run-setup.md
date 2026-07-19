# WBS 5.2.3 — First-run landing + two-step setup packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — children A, B, C shipped one PR each |
| Owner/domain | Deck / Presentation |
| Depends on | `3.12`, `5.1.2`, `5.2.2` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.2.3-01` |
| Test | `TEST-WBS-5.2.3-01` |

## Canonical inputs

- `create-deck.md` §§3–7 + full-screen first-run rules: focused
  full-screen (no dialog, no bottom nav, no carousel, no
  account/notification asks); landing CTAs Create/Import/Not now;
  Not now never auto-reopens onboarding; Step 1 = the two language
  selectors; Step 2 = deck name (required) + pair summary with Change +
  collapsed optional description; submit lifecycle
  idle/invalid/submitting/failure/success.

## Child boundaries (one child per PR)

| Child | Scope |
| --- | --- |
| **A** | Landing screen + Not-now persistence + the `description` schema/domain support Step 2 needs |
| **B** | Two-step setup: stepper composition over the 5.1.2 language step, Step 2 form (name/description/Change), drafts across steps, submit via `CreateDeckUseCase` |
| **C** | Success callout/handoff states + evidence (goldens, vi, E2E landing→deck) |

## Child A — landing + Not-now + description support (Done, 2026-07-19)

- **Schema/domain**: `decks.description` (nullable TEXT) — Step 2's
  optional field existed in the business spec but not in schema v1;
  added pre-release, snapshot + verifier helpers re-exported. Domain
  `Deck.description`, mapper, `CreateDeckUseCase(description:)`
  (trimmed, empty→null), repository create writing it atomically.
- `DismissFirstRunUseCase` — persists `firstRunLandingDismissed`;
  `wasDismissed()` feeds the 5.7 first-run redirect (boundary).
- `FirstRunLandingScreen` (route `/first-run`): §4 composition — MemoX
  wordmark, headline/body, primary `Create your first deck` →
  step 1 (the 5.1.2 language screen), tertiary `Not now` →
  dismissal persisted then empty Dashboard.
- **Import CTA present but inactive**: the first-run import flow is
  content-transfer scope (WBS 8.x); the secondary button activates when
  that flow lands (recorded handoff boundary).
- 3 widget tests: CTA composition (import pending), primary → step 1,
  Not now persisting the flag and landing home.

## Child B — two-step setup (Done, 2026-07-19)

- Step 1 = the 5.1.2 language screen, now continuing to step 2 instead
  of home; its selection draft turns keep-alive so "Change" returns to
  the previous selections (`create-deck.md` draft rule).
- `FirstRunDeckSetupScreen` (route `/first-run/deck`) — the §6
  composition: back arrow + "Step 2 of 2", required auto-gating deck
  name (create disabled until non-empty), the chosen-pair summary with
  **Change** back to step 1, collapsed **Optional** description with
  Show/Hide, and nothing else (no default view, no cards, no study
  settings).
- `first_run_deck_viewmodel.dart` — keep-alive deck draft
  (name/description/`retryDeckId`) surviving Change/back and cleared on
  success; `ensureRetryDeckId` gives the kept-id submit idempotency;
  `CreateFirstDeckViewmodel.createDeck` resolves the active pair and
  creates through `CreateDeckUseCase` (missing pair fails typed —
  never guessed).
- Failure surfaces per §7: `deckName` validation and sibling
  duplicates inline under the field; other failures as the banner;
  submitting disables fields and the CTA.
- 4 widget tests (summary + name gating, draft across Change/back,
  create persisting name+description then home, inline duplicate) and
  the 5.1.3 E2E extended through step 2 to the real home with the deck
  persisted.

## Child C — evidence + hardening (Done, 2026-07-19)

- **E2E from the landing** over the production router: landing →
  Create your first deck → both language selections → step 2 → deck
  created → home, with pair + deck persisted.
- vi locale renders for the landing and step 2; 8 committed goldens
  (landing + deck setup × light/dark × 390/1024).
- Shared hardening surfaced by the 390 goldens: `MxButton` labels now
  flex with single-line ellipsis, so long localized labels can never
  overflow the button row.
- **Success-callout boundary**: the §7 success surface is the Library
  with the new deck highlighted and the contextual callout — that
  surface literally does not exist until `5.2.4`, so the callout ships
  with the Library screen (recorded; the WBS row's "callout states"
  requirement transfers there). Until then success lands on the home
  placeholder.

## Acceptance and test procedure

`AC-WBS-5.2.3-01`: the full landing→two-step→created-deck journey
matches §§4–7 with drafts kept across steps and typed
failure/duplicate handling; Not now is durable; no dialog anywhere in
first-run.

`TEST-WBS-5.2.3-01`: per-child suites in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Completed 2026-07-19: A (#69), B (#70), C closed the packet. `5.2.4`
  (Library/open deck, XL) is next and owns the success callout.
