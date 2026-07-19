# WBS 4.7 — Migration system implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Data / Persistence lifecycle |
| Depends on | `4.2` — Done |
| Decision gates | DG-06 (ADR-004), `docs/database/migration-policy.md` (Accepted) |
| Acceptance | `AC-WBS-4.7-01` |
| Test | `TEST-WBS-4.7-01` |

## Canonical inputs

- `docs/database/migration-policy.md`: snapshot every released schema
  version; validate integrity before use; typed recovery on failure;
  never infer policy migrations from schema versions.
- Drift schema tooling (`drift_dev schema dump/generate`).

## Scope

- `drift_schemas/drift_schema_v1.json` — the committed schema v1
  snapshot (policy rule 1), exported with `dart run drift_dev schema
  dump`.
- `test/data/database/generated_migrations/` — drift-generated
  verification helpers from the snapshot; regenerated alongside any new
  snapshot with `dart run drift_dev schema generate`.
- `lib/data/database/migrations/app_migrations.dart` — the guided
  migration structure: `onCreate` creates the full v1 schema;
  `_upgrade` is the documented landing site for v2+ step-by-step
  migrations; `beforeOpen` enables foreign keys on every connection and
  after an upgrade runs `PRAGMA foreign_key_check`, surfacing
  violations as `DataCorruptionFailure` instead of serving a broken
  store (rule 3/5). `AppDatabase.migration` delegates here.
- `test/data/database/migration_test.dart` — `SchemaVerifier` proves a
  freshly created database matches the exported snapshot exactly, and a
  seeded fixture passes `foreign_key_check` + `integrity_check`.

Toolchain note: `drift` is pinned to `2.34.0` (was `^2.34.2`) — the
schema tooling in `drift_dev 2.34.0` compiles against the drift-3
preview API of exactly that runtime, and `drift_dev ≥2.34.1` remains
excluded by the analyzer-13 ceiling (riverpod_generator). Revisit both
pins together at the next toolchain advance.

Recorded boundaries:

- With only one released version there is no old→new upgrade path yet;
  the first v2 migration must add its snapshot, a step-by-step upgrade
  in `_upgrade`, and old→new + rollback/interrupted fixtures per the
  policy's fixture list. On-device Web/Android migration evidence is
  Tier-1 platform scope (5.7.4/16.1).
- SRS policy migration (policy §2) is explicitly out of scope until an
  accepted product decision exists.

## Acceptance and test procedure

`AC-WBS-4.7-01`: schema v1 has a committed snapshot; database creation
provably matches it; the guided upgrade structure exists with an
integrity gate that fails typed rather than serving corrupted data.

`TEST-WBS-4.7-01`: `migration_test.dart` in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `4.7` Done; next candidate `4.8`
  (DI graph) wiring database + repositories into providers.
