# WBS 5.2.3 — First-run landing + two-step setup packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — child A Done (2026-07-19); B, C pending |
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

## Acceptance and test procedure

`AC-WBS-5.2.3-01`: the full landing→two-step→created-deck journey
matches §§4–7 with drafts kept across steps and typed
failure/duplicate handling; Not now is durable; no dialog anywhere in
first-run.

`TEST-WBS-5.2.3-01`: per-child suites in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.2.3
  flips Done when C merges; `5.2.4` (Library/open deck) may proceed
  after B.
