# WBS 5.4.1 — Initial progress implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-25) |
| Owner/domain | Learning / Domain |
| Depends on | `0.3` — Done; `5.3.1` — Done |
| Decision gates | DG-03, DG-04 |
| Acceptance | `AC-WBS-5.4.1-01` |
| Test | `TEST-WBS-5.4.1-01` |

## Canonical inputs

- `docs/business/learning-progress/initialise-card-progress.md`:
  - §1 one current progress per Card; initialisation idempotent by Card
    id; a new Card starts `new` / `box = 0` / `dueAt = null` and does
    **not** activate SRS; a Card missing state is safely repaired.
  - §3 Master flow: `Progress exists?` → return existing idempotently,
    else create New and commit; failure rolls back to a safe repair
    retry.
  - §4 initial state contract: `box = 0`, `dueAt = null`,
    `policyId = leitner-8-box-v1`, created/updated time, **no Attempt**.
  - §5 missing Card creates no orphan progress; a duplicate initialise
    returns the same state and never resets a learned Card.
  - §7 acceptance criteria 1, 2 and 5.
- `docs/business/learning-progress/srs-8-box-policy.md`: Box 0 is the
  un-activated New state — the reason "New" is a box value and not the
  absence of a row.
- Schema v1 `learning_progress`: `card_id` UNIQUE with
  `ON DELETE CASCADE`, `CHECK (box IN (0, 8) AND due_at IS NULL) OR
  (box BETWEEN 1 AND 7 AND due_at IS NOT NULL)`, and the
  `policy_id`/`policy_version` defaults.

## Scope

- `lib/data/database/queries/learning_progress.drift` —
  `insertNewProgressIfAbsent`: `INSERT OR IGNORE` pinning `box = 0` and
  `due_at = NULL` in SQL so the New contract cannot drift per call
  site, and so a concurrent initialise resolves to one row rather than
  a unique-constraint failure.
- `lib/domain/learning_progress/learning_progress_repository.dart` —
  new `initialiseNew` port method: insert-if-absent then read back
  inside one transaction, returning the **stored** state whether this
  call created it or found it.
- `lib/data/repositories/drift_learning_progress_repository.dart` —
  its implementation, through `mapSqliteConflicts`.
- `lib/domain/usecases/learning_progress/initialise_card_progress_usecase.dart`
  — the §3 Master flow:
  - existing progress → returned unchanged (a learned Card is never
    reset, `revision` untouched);
  - unknown Card → `ValidationFailure(field: 'cardId', code: 'unknown')`
    **before** any write, so no orphan row can exist;
  - Card present without state → repaired to New and audited through
    `AppLogger.warning`, per §2 "Existing Card missing state".
- `initialiseCardProgressUseCase` provider joins
  `lib/app/di/usecase_providers.dart`.
- `test/domain/usecases/initialise_card_progress_usecase_test.dart` over
  the real Drift graph.

**Out of scope** (named so the boundary is explicit, not forgotten):

- Import and backup-restore entry points (§2 rows 2–4) — they belong to
  `13.1` and `15.3`; this packet ships only the Create/repair rows.
- The due/new/relearn queue policy and the Library counter query that
  reads "New" as a missing row (`int-2`) — that is `5.4.2`.
- Any box or interval transition — `5.4.3` owns the policy math.

## Acceptance and test procedure

`AC-WBS-5.4.1-01`: initialising a Card's progress is idempotent by Card
id; the stored state is returned unchanged for a Card that already has
one; a Card with no state is repaired to New (`box = 0`,
`dueAt = null`, `policyId = leitner-8-box-v1`) with an audit record; an
unknown Card produces a typed validation failure and writes nothing; no
Attempt is created.

`TEST-WBS-5.4.1-01`: `initialise_card_progress_usecase_test.dart` in
every gate, covering — existing state returned unchanged (learned Card
keeps its box, due date and revision); repeat initialise yields exactly
one row; repair of a Card whose state was removed; unknown Card raising
`ValidationFailure` with no row written; concurrent initialise
resolving to one row; and the New contract asserted field by field.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `5.4.1` Done; next in the block
  is `5.4.2` (due/new/relearn query policy), which owns the `int-2`
  defect — the Library counters read "New" as a missing progress row,
  which this packet makes permanently false by construction.
