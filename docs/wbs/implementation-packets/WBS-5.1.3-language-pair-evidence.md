# WBS 5.1.3 — Language Pair tests/evidence implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — closes the 5.1 block |
| Owner/domain | Language Pair / QA |
| Depends on | `5.1.2` — Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.1.3-01` |
| Test | `TEST-WBS-5.1.3-01` |

## Coverage map (all in every gate run)

| Level | Suite |
| --- | --- |
| Unit (use cases, normalization, validation) | `test/domain/usecases/language_pair_usecases_test.dart` (8) |
| Repository (conflict codes, round-trips) | `test/data/repositories/content_repositories_test.dart` (pair coverage) |
| Provider (DI graph resolution end to end) | `first_run_language_evidence_test.dart` — provider group |
| Widget (states: disabled/search/save/duplicate/failure-draft) | `first_run_language_screen_test.dart` (5) |
| E2E (real `createAppRouter`: first-run → save → home) | `first_run_language_evidence_test.dart` — E2E group |
| Locale (vi copy renders end to end) | evidence suite — vi group |
| Light/dark + adaptive | 4 committed goldens: `first_run_{mobile-390,expanded-1024}_{light,dark}.png` |

## Recorded boundaries

- On-device Tier-1 E2E (fresh install, Web/Android, offline variants)
  is `5.7.4` scope by design; the widget-level E2E here runs the real
  router and real graph over an in-memory store.
- Golden baseline widths follow the 3.12 gate set (390 mobile baseline
  + expanded); the full width matrix belongs to the 3.11 catalog.

## Acceptance and test procedure

`AC-WBS-5.1.3-01`: every level of the pyramid names its suite; the E2E
path runs the production router; vi renders end to end; light/dark and
adaptive evidence is committed. **All satisfied 2026-07-19.**

`TEST-WBS-5.1.3-01`: the suites above in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success: `5.1` block complete (5.1.1/5.1.2/5.1.3 Done). Next in the
  critical path: `5.2` (Deck feature) starting with its domain child.
