# WBS 5.4.3 — Leitner 8 Box policy implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-25) |
| Owner/domain | Learning / Domain |
| Depends on | `0.3` — Done; `5.4.1` — Done |
| Decision gates | DG-03, DG-04 |
| Acceptance | `AC-WBS-5.4.3-01` |
| Test | `TEST-WBS-5.4.3-01` |

## Canonical inputs

- `docs/business/learning-progress/srs-8-box-policy.md`:
  - §1 policy id `leitner-8-box-v1`; grade engine takes `correct` or
    `wrong`; the clock is injected and the engine never calls
    `DateTime.now()`.
  - §2 Box 0 is pre-SRS; boxes 1..7 wait `1, 3, 7, 14, 30, 60, 120`
    days; Box 8 is mastered with no due date.
  - §3 activation result — Box 1, `nowUtc + 1d`, `srsActivatedAt` and
    `lastReviewedAt` set.
  - §4 terminal-grade normalisation, including wrong-sticky-per-session
    and its explicit non-propagation to a later relearn session.
  - §5 `correct → min(box + 1, 8)`, `wrong → max(box - 1, 1)`; no Box 9
    and no fall back to Box 0.
  - §6 schedule computation; §8 counters; §12 acceptance criteria.
- `docs/decision-tables/srs-8-box-v1.md` — `SRS8-001..028`.
- Guard `memox.study.srs_logic_single_source` (severity **error**),
  which pins `intervalForBox` and `boxAfterFinalization` to this file.

## Scope

`lib/domain/learning_progress/srs_8_box_policy.dart`, the whole of it:

- `leitner8BoxPolicyId`, `SrsGrade`, `SrsEvidence`, `SrsSchedule`.
- `intervalForBox` — the fixed 1/3/7/14/30/60/120 ladder. Box 0 and Box
  8 raise rather than return a fallback: neither is a scheduled box, so
  asking is a caller bug.
- `boxAfterFinalization` — promote capped at 8, demote floored at 1.
- `terminalGrade` — folds a session's committed evidence into one
  grade. Any `wrong`, `almost` or timeout in any round makes it
  `wrong`, even when a retry later passes (`SRS8-010`). **Empty evidence
  returns `null`**, not `correct`: §4 forbids a skipped or missing card
  under snapshot recovery being scheduled as if it had been answered.
- `activate` (`SRS8-001`) and `applyTerminalGrade`
  (`SRS8-003..009`, `SRS8-017..024`), both rejecting a foreign
  `policyId` with a typed failure (`SRS8-028`).

`test/domain/learning_progress/srs_8_box_policy_test.dart` — 37 tests
naming their row IDs, including an exhaustiveness assertion over the
`(box, grade)` space.

**Out of scope** (named so the boundary is explicit):

- **Persistence, transaction, idempotency and stale-writer conflict**
  (§7, `SRS8-011`, `SRS8-012`) — `5.4.4` owns the atomic
  attempt+schedule write. This policy computes and returns; it never
  persists.
- **The activation precondition** (§3's five completed modes with empty
  failed sets and no pending write) — that is Study Session state, so
  `activate` trusts its caller and `5.6.13` decides when to call it.
  `SRS8-002` is the absence of the call, not a branch here.
- **Queue eligibility** (`SRS8-013`, `-014`, `-015`, `-025`) — `5.4.2`,
  already Done.
- **Reset to Box 0** (`SRS8-016`), **intermediate attempts**
  (`SRS8-026`) and **practice outcomes** (`SRS8-027`) — reset flow and
  `5.6`.
- **Persisting `srsActivatedAt` / `lastReviewedAt`.** `SrsSchedule`
  carries both because §3 and §8 define them, but `learning_progress`
  has no column for either. Adding them is a schema change under the
  `4.7` migration contract, and it belongs with `5.4.4`, the first
  writer that needs to store them. The four fields the schema does hold
  — box, due, repetitions, lapses — are complete here.

## Acceptance and test procedure

`AC-WBS-5.4.3-01`: the transition math exists exactly once, in the
canonical pure-domain file, with no Flutter/Drift/Riverpod import and no
ambient clock; correct promotes one box capped at 8 and wrong demotes
one floored at 1; boxes 1..7 schedule at `nowUtc + interval`, Box 8 at
`null`; a wrong anywhere in a session sticks through retries but does
not cross into the next session; and a foreign policy id fails typed
rather than being reinterpreted under v1.

`TEST-WBS-5.4.3-01`: `srs_8_box_policy_test.dart` in every gate — the
interval ladder and the 24-hour day; activation and its
already-activated rejection; all 16 `(box, grade)` transitions with an
exhaustiveness assertion; the promote cap and demote floor; counters;
grade folding including sticky-wrong, `almost`/timeout, empty evidence
and cross-session promotion; policy identity; determinism and UTC.

## Findings recorded

**The decision table is not exhaustive.** `SRS8` states 15 of the 16
`(box 1..8, grade)` transitions — **Box 7 + `wrong` has no row** — while
its header calls `SRS8-001..028` the complete v1 executable contract.
§5's formula settles the behaviour (Box 6, `+60d`) and the suite covers
it as a derived case, but assigning an ID is the decision-table owner's
call, since other documents cite that ID space. Recorded in
`docs/decision-tables/srs-8-box-v1.md` under *Coverage gap*.

## Failure and completion

- Success: register evidence recorded, `5.4.3` Done; next in the block
  is `5.4.4` (attempt/schedule transaction), which becomes the only
  writer of what this policy computes and owns `SRS8-011`/`-012`.
