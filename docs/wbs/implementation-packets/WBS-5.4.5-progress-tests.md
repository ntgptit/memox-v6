# WBS 5.4.5 — Progress tests

- Status: **Done** (2026-07-25)
- Size: XL on paper; most of the surface was already covered by `5.4.2`–`5.4.4`
- Depends on: `5.4.2`–`5.4.4`
- Boundary: full policy decision table, plus property, boundary, timezone,
  idempotency, repository and migration tests

## Audit before writing anything

This row asks for seven categories of coverage. Five were already satisfied by
the rows that built the behaviour, so the work here was to find the two that
were not rather than to restate the five that were.

| Category | State at audit |
| --- | --- |
| Full policy decision table | Covered — all **28** `SRS8-*` rows are named by tests, with an exhaustiveness assertion over the `(box, grade)` space (`5.4.3`) |
| Property | Covered — `srs_8_box_policy_property_test.dart` holds the transition invariants across every activated box |
| Idempotency | Covered — `5.4.4` child C, across a file-backed process restart |
| Repository | Covered — `5.4.4` children A and B |
| Migration | Covered — `5.4.4` child A, v1 → v2 including a surviving legacy row |
| **Boundary** | **Partial** — only `due_at == nowUtc` was asserted |
| **Timezone** | **Missing on the read side** — documented in a comment, held by nothing |

## What this row added

### Boundary: the two instants either side of equality

The comparison is `due_at <= nowUtc`, so equality alone is the least
interesting third of it. A card one millisecond before `now` is due; one
millisecond after is not. A millisecond is the smallest step the stored epoch
can express, which makes this the tightest available form of the assertion.

### Timezone: the read side had a comment, not a test

`LoadStudyQueueCountsUseCase` states the contract in its doc comment —
timezone belongs to presentation and to the local-day new-card limit, never to
which instants have passed — and `surface-due-cards.md` §9 requires it: *"Due
eligibility luôn dùng UTC instant equality/before; timezone change không làm
đổi persisted `dueAt`."* Nothing enforced either half.

Dart cannot repoint the process timezone mid-test, so the equivalent check is
to express the **same instant** with a different UTC offset (`19:00+07:00`
against the fixture's `12:00Z`). If any step compared wall-clock fields rather
than the instant, the two readings would disagree. The second test covers the
other half: reading the queue through a different offset moves neither the
stored `dueAt` nor the revision — asking what is due is a selection, and a
timezone change is not an event the store should notice at all.

### The clock port itself

`app_clock_test.dart` pinned a `withClock` zone that was already UTC, so it
passed whether or not `nowUtc()` converted. The existing `isUtc` assertion does
catch a dropped `.toUtc()` — `DateTime.now()` is never flagged UTC — but only
via the flag; it says nothing about the value. The added test runs inside a
**non-UTC** zone and asserts the instant survives conversion, which is what
every caller relies on without re-checking.

Verified by mutation: removing `.toUtc()` from `SystemClock.nowUtc()` fails
this test (and the flag test), and both pass again once restored.

## Findings

No defect. The clock port, the queue comparison and the policy arithmetic all
behaved as specified under every new case — including the millisecond
boundaries and the offset-shifted readings. `SystemClock` converts and
`FakeClock` normalises in both its constructor and its setter, so the
"timezone-invariant by construction" claim in the use case's comment is now
also true by test.

## Evidence

- `test/domain/usecases/study_queue_counts_usecase_test.dart` — the due
  boundary to the millisecond either side of `now`; the same instant in
  another offset classifying identically; a cross-offset read leaving `dueAt`
  and `revision` untouched.
- `test/core/time/app_clock_test.dart` — a non-UTC ambient clock converted
  with its instant preserved.
- Already-standing evidence for the other five categories:
  `srs_8_box_policy_test.dart` (28 rows), `srs_8_box_policy_property_test.dart`,
  `progress_repositories_test.dart`, `srs_exactly_once_restart_test.dart`,
  `migration_test.dart`.
