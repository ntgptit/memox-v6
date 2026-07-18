# Tier-1 resource and performance budgets

- Status: **Accepted verification baseline**
- Owner: Architecture / QA
- Platforms: Web + Android

These values define repeatable test profiles and responsiveness gates. They are not user-facing data
caps. A lower product cap requires a separate Product decision and migration/export behavior.

## Canonical data profiles

| Profile | Decks | Cards | Attempts/history | Due now | Purpose |
| --- | ---: | ---: | ---: | ---: | --- |
| Small | 5 | 100 | 1,000 | 20 | unit/widget and low-end smoke |
| Standard | 50 | 5,000 | 50,000 | 500 | routine integration/E2E |
| Large | 200 | 20,000 | 250,000 | 2,000 | release performance, backup and migration |

Content fixtures include long Vietnamese/mixed-script text, tags/translations, missing audio,
multiple Language Pairs and a deep but valid Deck hierarchy.

## Budgets after local database open

| Operation | Standard p95 | Large p95 | Failure rule |
| --- | ---: | ---: | --- |
| Today projection | 200 ms | 500 ms | Must remain cancellable and show retained state/recovery |
| Due queue page (100 rows) | 150 ms | 350 ms | Stable deterministic ordering; no full-table UI load |
| Local search first page | 200 ms | 500 ms | Debounced/cancellable; stale result cannot replace newer query |
| Commit terminal answer | 100 ms | 250 ms | One transaction; timeout/retry cannot double schedule |
| Open Deck/Card list page | 150 ms | 350 ms | Paged/builder rendering; no unbounded materialization |
| Backup/restore preflight | 2 s | 5 s | No mutation before validation completes |

Frame rendering targets the current Flutter 60 Hz budget: no sustained task-induced frames above
16.7 ms during scrolling or answer transitions. File/audio/network picker time is excluded from local
operation timing but must remain cancellable with explicit progress.

## Storage and import safety

- Before import/restore, estimate required space and require available space of at least
  `2 × incoming payload + current database transaction overhead`.
- Streaming parsers and batched transactions are mandatory for the Large profile; whole-file UI
  decoding is not allowed.
- Web storage quota denial and Android low-storage failures must leave the prior database usable.
- Benchmarks record device/browser, build mode, dataset seed, warm/cold state and percentile samples.

## Gate

WBS performance, import, backup, migration and first-learning release evidence must name the profile
used. A budget miss blocks the affected release gate unless Architecture/QA accepts a measured,
time-bounded exception with owner and target.
