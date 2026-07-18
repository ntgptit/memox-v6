# ADR-006 — Navigation contract

- Status: **Accepted**
- Owner: Architecture / Presentation
- Accepted: 2026-07-18

## Decision

Use GoRouter with `RouteNames`, `RoutePaths`, and application navigation
extensions/wrappers. Feature UI contains no raw route strings and does not call
`Navigator` directly.

The learning entry contract is explicit:

1. Picker selects queue/scope/mode.
2. Primary CTA revalidates eligibility.
3. Start command creates or resumes the atomic session snapshot.
4. Navigation occurs only after a successful start/resume result.

A paused session outranks a new start. Due, relearn, new-learning, and practice
routes remain semantically distinct even if they share a shell. Web URLs and
browser back/forward preserve stable identity and do not repeat mutations.

## Verification

Route tests cover constants, deep links, invalid/stale IDs, browser back/forward,
overlay back/dismiss, start failure, paused-session precedence, result return,
notification entry, offline restart, and no duplicate start command.
