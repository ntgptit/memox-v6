# WBS 4.1 — Database runtime implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Data + Architecture / Persistence |
| Depends on | `0.2`, `1.1`, `1.6` — Done (drift_dev unblocked by the toolchain advance, PR #40) |
| Decision gates | DG-06 (ADR-004) |
| Acceptance | `AC-WBS-4.1-01` |
| Test | `TEST-WBS-4.1-01` |

## Canonical inputs

- `docs/architecture/adr/ADR-004-local-persistence-platforms.md`: Web and
  Android share one Drift schema with platform-specific tested openers.
- WBS §5.2 Drift contract: open off the main isolate on native, approved
  web opener on web.
- Toolchain: `drift 2.34.2` runtime + `drift_dev 2.34.0` (analyzer-12
  evidence in the 1.1 packet and PR #40).

## Scope

Create:

- `lib/core/database/database_opener.dart` —
  `openAppDatabaseExecutor(name:)` over `drift_flutter`'s `driftDatabase`:
  native path opens in a background isolate (off the UI isolate per
  ADR-004), web path is the wasm opener wired to `sqlite3.wasm` /
  `drift_worker.js`. The executor is lazy — construction is side-effect
  free.
- `lib/data/database/app_database.dart` — the one shared `AppDatabase`
  (`@DriftDatabase`, `schemaVersion 1`); `open()` production constructor
  through the platform opener and `forTesting(executor)` for in-memory/
  migration fixtures. Schema v1 tables land with WBS 4.2.
- `test/data/database/app_database_test.dart` — lifecycle suite over
  in-memory executors: schema version + query execution +
  `PRAGMA user_version`, idempotent close ending the connection and clean
  reopen. Opener construction laziness proved flaky to assert in unit
  tests (drift_flutter internals schedule async work we do not own), so
  opener execution is exclusively the recorded platform-evidence
  boundary below.
- `analysis_options.yaml` — analyzer now excludes generated output
  (`*.g.dart`/`*.freezed.dart`/generated l10n), matching the guard's
  excludes; the first Drift codegen output surfaced the gap.

Recorded boundaries:

- **Web wasm assets** (`sqlite3.wasm`, `drift_worker.js` under `web/`) are
  build artifacts provisioned with the Tier-1 web smoke evidence
  (WBS 5.7.4); the opener code path is complete and inert until then.
- On-device Android/Web opener execution is Tier-1 platform evidence
  (5.7.4/16.1), not unit-test scope.

## Acceptance and test procedure

`AC-WBS-4.1-01`: one shared database class opens through the platform
opener factory; lifecycle (open/query/close/reopen) is test-verified over
in-memory executors; the native path runs off the UI isolate by
construction; no schema tables exist before 4.2. Full canonical gate passes.

`TEST-WBS-4.1-01`: `app_database_test.dart` (3 tests) in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `4.1` Done, then author `4.2`
  (schema v1 design, XL — child boundaries per table group) next.
