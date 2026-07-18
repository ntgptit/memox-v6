# SRS8-v1 — Leitner 8 Box exhaustive decision table

Source policy: [SRS Policy v1](../business/learning-progress/srs-8-box-policy.md). `nowUtc` là injected instant; một day = 24 hours. IDs `SRS8-001..016` preserve the canonical summary IDs in the policy document.

| ID | Current/Given | Event | Next/Then | `dueAt` |
| --- | --- | --- | --- | --- |
| SRS8-001 | Box 0, five-mode pipeline complete | Activate | Box 1 | `nowUtc + 1d` |
| SRS8-002 | Box 0, incomplete/paused | Checkpoint | Box 0 | `null` |
| SRS8-003 | Box 1 | correct | Box 2 | `nowUtc + 3d` |
| SRS8-004 | Box 1 | wrong | Box 1 | `nowUtc + 1d` |
| SRS8-005 | Box 4 | correct | Box 5 | `nowUtc + 30d` |
| SRS8-006 | Box 4 | wrong | Box 3 | `nowUtc + 7d` |
| SRS8-007 | Box 7 | correct | Box 8 | `null` |
| SRS8-008 | Box 8 | correct | Box 8 | `null` |
| SRS8-009 | Box 8 | wrong | Box 7 | `nowUtc + 120d` |
| SRS8-010 | Any activated Box; wrong/almost/timeout then passes retry | Aggregate | terminal `wrong`; apply one decrement | Interval of resulting box |
| SRS8-011 | Same `terminalOutcomeId` retry | Apply | Return exact prior result | Unchanged |
| SRS8-012 | Different outcome on stale progress version | Apply | Typed conflict | Unchanged |
| SRS8-013 | Box 1..7, `dueAt == nowUtc` | Eligibility | Due | Unchanged |
| SRS8-014 | Box 8 | Queue build | Excluded from Due/New/Relearn | `null` |
| SRS8-015 | Box 1..7 hidden and due | Eligibility | Excluded | State preserved |
| SRS8-016 | Any Box | Reset | Box 0 | `null` |
| SRS8-017 | Box 2 | correct | Box 3 | `nowUtc + 7d` |
| SRS8-018 | Box 2 | wrong | Box 1 | `nowUtc + 1d` |
| SRS8-019 | Box 3 | correct | Box 4 | `nowUtc + 14d` |
| SRS8-020 | Box 3 | wrong | Box 2 | `nowUtc + 3d` |
| SRS8-021 | Box 5 | correct | Box 6 | `nowUtc + 60d` |
| SRS8-022 | Box 5 | wrong | Box 4 | `nowUtc + 14d` |
| SRS8-023 | Box 6 | correct | Box 7 | `nowUtc + 120d` |
| SRS8-024 | Box 6 | wrong | Box 5 | `nowUtc + 30d` |
| SRS8-025 | Deleted Card | Eligibility/apply | Excluded/not found; no new Progress | N/A |
| SRS8-026 | Intermediate Attempt | Commit | History only | Unchanged |
| SRS8-027 | Practice terminal outcome | Finalize | History only | Unchanged |
| SRS8-028 | Unknown `policyId` | Apply | Typed policy error | Unchanged |

Migration contract: v1 initial creation stores `policyId=leitner-8-box-v1`. A future policy requires a new policy ID, explicit old→new mapping, dry-run impact counts, atomic migration, rollback/recovery and fixture tests for every source state. No in-place reinterpretation of persisted v1 history.
