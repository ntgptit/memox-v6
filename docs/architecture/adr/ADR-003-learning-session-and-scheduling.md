# ADR-003 — Learning sessions, queues, and scheduling

- Status: **Accepted**
- Owner: Product / Learning domain
- Accepted: 2026-07-18
- Decision gate: DG-03
- Policy ID: `leitner-8-box-v1`

## Decision

New learning is a fixed five-stage sequence: Review, Match, Guess, Recall, Fill.
The picker plus explicit primary CTA chooses scope and eligible flow. Guess has
exactly five distinct-meaning options. Recall has a 20-second deadline driven by
an injected clock/timer. A mandatory pure-domain `StudyModeFactory` resolves the
five user-facing strategies plus the session-only `srsBinaryReview` strategy;
the factory and strategies never persist Attempts or checkpoints.

Queues are separate commands and projections:

- New learning: Box 0 cards; completion of all required stages activates Box 1.
- Due review: cards with `dueAt <= nowUtc`; fixed mode plan
  `due-review-binary-v1 = [srsBinaryReview]`.
- Relearn: failed cards from a finalized source session. Start snapshots Guess
  when a five-meaning pool exists, otherwise `srsBinaryReview`; Resume never
  reselects the plan.
- Practice: non-scheduling practice; it never mutates SRS schedule.

The sole production source for transition math is
`lib/domain/learning_progress/srs_8_box_policy.dart`. Repository/data code calls
that policy and owns atomic persistence; it must not duplicate interval or box
transition math.

## Terminal scheduling

Intermediate attempts do not schedule. One terminal aggregate outcome schedules
exactly once using an idempotency key. Correct advances one box; sticky-wrong
decreases one box with floor Box 1. Box 8 is mastered with `dueAt = null`.
Reset returns to Box 0. Instants are persisted in UTC.

A Relearn terminal outcome intentionally schedules again from the current
persisted box. Therefore a first-pass correct Relearn may promote a Card that
the source session previously demoted; this is accepted v1 behavior, not a
sticky-wrong carry-over across sessions.

## Verification

Decision-table and property tests cover five-stage activation, Guess pool
eligibility, Recall deadline/tap races, sticky-wrong, retry, concurrent terminal
writers, crash/restart, UTC boundary, Box 8, reset, and policy-version migration.
