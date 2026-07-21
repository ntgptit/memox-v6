# Onboarding completion — design spec

- Date: 2026-07-21
- Branch: `feat/onboarding-slice`
- Status: **Proposed** (awaiting user review before implementation plan)
- Owning docs: `docs/business/navigation`, `docs/business/deck/create-deck.md`,
  `docs/business/language-pair/create-language-pair.md`, kit `MemoX Design System v4`

## 1. Context — what onboarding already is

The first-run flow is substantially built and measured. The kit-parity gate
(`evidence/parity/summary.json`, 22 state-themes, all ≤3%) already covers:
landing (default), step 1 (complete selection, validation error MX-VIS-005),
step 2 (name filled, optional expanded, submitting, submit failure, name too
long MX-VIS-014, resume draft MX-VIS-015), Library empty, Card Editor create.

A full runtime walkthrough (release Flutter Web, 375×812, fresh install) on
2026-07-21 confirmed the happy path and every measured branch renders
correctly end to end: landing → step 1 (search / no-result / native·English
labels) → step 2 (pair summary + Change, name-too-long inline, draft-resume
banner + Start over) → Library success (new deck + New badge + first-deck-ready
callout + persistent tab bar).

## 2. Goal — what "complete" means here

The WBS defines slice completion as **outside-in**: close every branch the kit
draws, including error and edge branches, and measure each so it cannot drift
(`docs/wbs/memox-v6-development-wbs.md`, onboarding-slice note). "Complete
onboarding" therefore means: close the branches the runtime walkthrough proved
are missing or wrong, and add parity coverage for the branches that render but
were never measured.

Explicitly **out of scope** (owner-deferred, not incomplete):

- **Import flow** — landing "Import existing cards" is a disabled no-op; owned
  by WBS 13.1. The CTA stays disabled.
- **"Not now" → empty Today** — lands on the Home placeholder today; the empty
  Today state (MX-VIS-002) defers with WBS 5.7, which the STOP RULE halts.

## 3. Defects found by runtime walkthrough

| # | Defect | Observed | Kit contract |
| --- | --- | --- | --- |
| 1 | Same-language surfaced wrong | Korean→Korean: Continue stays enabled; submit shows the generic "Could not save · try again" banner. The domain rejects it (`CreateLanguagePairUseCase` throws `ValidationFailure(field:'nativeLanguageCode', code:'not-distinct')`), but a deterministic invalid is presented as a retryable failure — retrying the same selection always fails, and the copy never says to change a language. | `create-language-pair.md §5` lists "same language if disallowed" as a distinct state; §1 keeps draft on failure. |
| 2 | Stale error banner | After the same-language failure, correcting meaning → Vietnamese does not clear the "Could not save" banner; it lingers until the next submit. | Error state should reflect the current draft, not a superseded attempt. |
| 3 | Success callout layout broken @390 | "Open deck" renders as a large heading beside a cramped 2-line title / 5-line body column, because `MxBanner` places its `action` in the top-level `Row` to the right of the title/body `Expanded`. | `create-deck.md §7`: `Open deck` is a link on its own row **below** the body, with `×` trailing. |

**Common root cause:** all three states are absent from the 22 measured parity
states (same-language error, stale-error-cleared, first-deck-ready callout), so
they drifted without the gate noticing. This is the same layer-first closure
gap the onboarding-slice note describes.

## 4. Workstreams

Each workstream is TDD: a failing test (widget and/or parity) first, then the
change, then verification. No workstream touches Import (13.1) or empty-Today
(5.7).

### WS1 — Same-language: prevent, don't fail (defect #1)

**Decision (user, 2026-07-21):** disable Continue + inline guidance.

Presentation-only; the domain rule already exists and is correctly typed.

- In `first_run_language_screen.dart`, derive
  `isSameLanguage = draft.learningCode != null && draft.learningCode == draft.nativeCode`.
- `Continue` is enabled only when `isComplete && !isSameLanguage && !isSaving`.
- When `isSameLanguage`, render an inline error under the **meaning** field
  (reuse `_RequiredSelectionError`, a live-region sm error line), with a new
  localized message (en + vi), e.g. "Choose a different meaning language."
- The user can never reach the submit that produces the generic
  "Could not save" banner via same-language.

Acceptance:

- Korean→Korean: Continue disabled, inline guidance under meaning field.
- Changing either language to make them distinct clears the guidance and
  enables Continue.
- The generic save-failure path is unreachable for same-language input.
- Widget test over the real graph; parity state added in WS4.

### WS2 — Clear the save failure when the draft changes (defect #2)

- When the language draft changes (learning or meaning set), reset the
  `saveLanguagePairViewmodelProvider` action state so a prior failure banner
  clears immediately.
- Scope: the language draft viewmodel / the screen's listener wiring. Follow
  the existing `mx_action_runner` / `listenMxAction` pattern; do not hand-roll
  a second error channel.

Acceptance:

- After a save failure, changing a selection removes the error banner without
  requiring another submit.
- Widget test asserting the banner is gone after a draft change.

### WS3 — Success callout matches kit §7 (defect #3)

The success callout is a **titled** block (title + multi-line body) with an
action **below** the body — a composition neither current primitive provides:
`MxBanner` places its action trailing (the bug); `MxActionCallout` is a
one-line notice with a trailing action (correct for the draft-resume banner it
already backs, wrong for a titled multi-line callout).

**Approach:** extend `MxBanner` with an optional below-body action slot
(additive, e.g. `footerAction`), leaving the existing trailing `action`
behavior unchanged, then have `_FirstDeckCallout` use it so "Open deck" sits on
its own row below the body with `×` trailing.

**Kit-contract gate:** `MxBanner` is a frozen `Mx*` component. This change is
additive (new optional param, no rename / no id change) but still touches the
kit contract, so it MUST go through the **memox-design skill** and be grounded
in the kit's banner-with-below-action spec before implementation. If the kit
defines a distinct component for this composition, use that instead of
extending `MxBanner`. Resolve this in the implementation plan, not by
assumption.

Acceptance:

- At 390 width, "Your first deck is ready" title is one line, body wraps full
  width, "Open deck" is a link on its own row below the body, `×` trailing —
  matching `create-deck.md §7`.
- The six existing `MxBanner` consumers are visually unchanged (trailing-action
  behavior preserved).
- Kit-parity state added in WS4.

### WS4 — Close the outside-in gap: measure the drifted branches

Add kit-parity states so the branches that drifted cannot drift again:

- Step 1: same-language guidance state.
- Step 1: language sheet no-result state.
- Library: first-deck-ready success callout state.

Each new state is measured at 390, light + dark, against its kit shot at <3%,
registered in the parity spec and `evidence/parity/summary.json`, and bound to
its master-flow node per `tool/parity/flows.ts` (enter through app launch, no
deep-link bypass).

Acceptance:

- The three states appear in the parity summary and pass ≤3%.
- Each entered through `enterFlow`, not `deepLinkEntry`.

## 5. Testing & verification

- Widget tests (WS1, WS2) run over the real provider graph, following the
  existing first-run test patterns.
- Parity tests (WS3, WS4) render the real Flutter Web build through Playwright
  and pixel-diff against kit shots.
- Final gate: `node tool/verify/run.mjs` (full) must pass — guard, analyze,
  format, l10n, codegen, all tests, docs/traceability.
- Runtime re-walk of the full onboarding flow after implementation to confirm
  each defect is closed in the real app.

## 6. Out of scope

- Import flow (WBS 13.1) — CTA stays disabled.
- Empty Today for "Not now" (WBS 5.7, STOP-RULE halted).
- Any normal-mode (non-first-run) create-deck dialog work.
- The 7 orphaned shared primitives awaiting halted consumers (tracked
  separately; not part of onboarding).
