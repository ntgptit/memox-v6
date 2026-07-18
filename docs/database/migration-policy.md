# Schema and policy migration contract

- Status: **Accepted**
- Owner: Data / QA

## Rules

1. Export and retain a schema snapshot for every released schema version.
2. Test every supported old-version -> current-version path on Web and Android.
3. Validate compatibility and integrity before destructive mutation.
4. Run a migration transaction where the platform supports it; otherwise use a
   recoverable staged copy/swap with an integrity marker.
5. A failed migration preserves or restores the last valid store and returns a
   typed recovery result.
6. Never infer a business-policy migration from a schema version alone.

## SRS policy migration

Schema version and `policy_id`/`policy_version` are separate. The baseline policy
is `leitner-8-box-v1`. A future policy change requires:

- an accepted Product decision and migration ADR;
- explicit old -> new state mapping;
- due-date and mastered/reset behavior;
- idempotent resumable migration;
- deterministic clock fixtures;
- rollback/repair and statistics-projection reconciliation tests.

## Fixtures and evidence

Version-control schema snapshots and small non-sensitive fixture databases for
empty, minimum, dense, paused-session, due-card, corrupt, and interrupted
migration states. Generated databases and secrets are not committed.
