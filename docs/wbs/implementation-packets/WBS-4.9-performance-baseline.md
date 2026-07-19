# WBS 4.9 — Performance baseline implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Data / Performance |
| Depends on | `4.4–4.6` — Done; `1.7` dense fixtures |
| Decision gates | DG-06 |
| Acceptance | `AC-WBS-4.9-01` |
| Test | `TEST-WBS-4.9-01` |

## Canonical inputs

- WBS 4.9: query plans/index checks, pagination/stream limits,
  dense-library fixtures and latency/memory budgets.
- The schema-v1 indexes shipped in 4.2 and the 1.7 dense fixture.

## Scope

- `lib/data/database/query_limits.dart` — the pagination policy:
  `defaultPageSize = 25`, `maxPageSize = 100`, `clampPageSize`. Every
  paged read flows through named limits — no ad hoc page sizes.
- `test/data/database/performance_baseline_test.dart` —
  - **Query-plan checks** (`EXPLAIN QUERY PLAN`) proving the hot paths
    search their indexes instead of scanning: card paging per deck
    (`idx_flashcards_deck`), the due queue
    (`idx_learning_progress_due`), root/child deck listings (the
    sibling-name partial indexes) and attempt replay lookup (the unique
    idempotency index).
  - **Limit checks**: clamp policy; dense-library paging returns
    exactly one page; streams emit bounded first snapshots.
  - A generous in-test stopwatch (<500 ms/page on the dense fixture)
    catches order-of-magnitude regressions without becoming flaky.

## Budgets (recorded targets, Tier-1 evidence on device)

| Metric | Budget | Where verified |
| --- | --- | --- |
| Card page query (25 rows, dense library) | ≤ 50 ms | 5.7.4/16.1 device runs; unit guard at 500 ms |
| Due-queue query (25 rows) | ≤ 50 ms | same |
| First stream emission per deck | ≤ 100 ms | same |
| Steady-state DB memory | ≤ 32 MB | device profiling at 16.1 |

On-device latency/memory measurement is Tier-1 platform evidence — the
unit suite pins plans and limits, the device runs pin the budgets.

## Acceptance and test procedure

`AC-WBS-4.9-01`: hot queries provably use their indexes; page sizes are
policy-bounded; dense fixtures back the checks; budgets are recorded
with their measurement points.

`TEST-WBS-4.9-01`: `performance_baseline_test.dart` in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `4.9` Done; the `4.10`
  architecture/data foundation gate is the next item.
