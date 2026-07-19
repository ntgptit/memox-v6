# WBS 5.2.6 — Deck tests/evidence implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — closes the 5.2 Deck block |
| Owner/domain | Deck / QA |
| Depends on | `5.2.3–5.2.5` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.2.6-01` |
| Test | `TEST-WBS-5.2.6-01` |

## Coverage map (all in every gate run)

| Level | Suite |
| --- | --- |
| Decision tables | `deck_domain_test` (§0 derivation), `content_choice_test` (per-state action sets + reopen-on-Empty) |
| Transaction/property | `create_deck_usecase_test` (atomic create, kept-id retry), `constraints_schema_test` (rollback), evidence suite (seeded 200-case normalization sweep: idempotent, case/trim-insensitive) |
| Repository/store | `deck_domain_test` (pair invariant), 4.3/4.6 suites |
| Provider | evidence suite — library/children/subtree providers over the DI graph |
| Widget | landing (3), setup (4), library (3), deck detail (5), dialog/states (5), content choice (4) |
| E2E | first-run landing→deck→Library on the production router (5.2.3C) |
| Locale | vi renders: Library, empty deck (+ first-run suites) |
| Light/dark | 4 new goldens (library, deck-parent × light/dark at 390) + the 8 first-run goldens |

## Recorded boundaries

- On-device Tier-1 E2E and offline variants stay `5.7.4` scope.
- The full width matrix belongs to the 3.11 catalog; dense-Library
  golden widths follow the 3.12 baseline set.

## Acceptance and test procedure

`AC-WBS-5.2.6-01`: every pyramid level names its suite; decision
tables pin §0 and the action sets; property evidence sweeps
normalization; goldens cover light/dark at the baseline width. **All
satisfied 2026-07-19.**

`TEST-WBS-5.2.6-01`: the suites above in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- The 5.2 Deck block is complete (5.2.1–5.2.6 Done). Next in the
  critical path: `5.3.1` (Flashcard domain/data, XL).
