# WBS 4.8 — App DI graph implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Architecture / App wiring |
| Depends on | `1.11`, `4.1–4.7` — Done |
| Decision gates | Riverpod foundation contract; DG-06 |
| Acceptance | `AC-WBS-4.8-01` |
| Test | `TEST-WBS-4.8-01` |

## Canonical inputs

- WBS 4.8: keep-alive generated providers for DB/DAO/repos/services;
  startup fail-fast graph test.
- `docs/architecture/riverpod-foundation.md`: infrastructure providers
  are generated, keep-alive, and live in `lib/app/di/`.

## Scope

- `lib/app/di/data_providers.dart` — `appDatabaseProvider` (opens the
  production database through the platform opener, closes it on
  dispose) plus the eight repository providers, all
  `@Riverpod(keepAlive: true)` and typed as the **domain ports** —
  widgets never touch these directly (guard) and no Drift type escapes.
- **DAO providers by design do not exist**: DAOs are data-layer
  internals reachable only through repositories; a DAO provider would
  invite the exact bypass the architecture forbids.
- `warmUpDiGraph(container)` (in `data_providers.dart`; the SQL probe
  itself lives on `AppDatabase.probeConnection` in the data layer per
  the guard): reads every
  infrastructure provider and touches the database once so a miswired
  graph or a failed open/migration surfaces at launch inside the
  bootstrap error zone, not lazily on some later screen. Bootstrap
  invokes it when the first screen lands (the current `MemoxApp` shell
  has no consumer yet — recorded boundary).
- `test/app/di/di_graph_test.dart` — the fail-fast graph test: the
  warmed graph resolves every port over one shared database instance;
  overriding `appDatabaseProvider` swaps the whole graph end to end
  (repository reads see seeded rows); a closed database fails the
  warm-up immediately.

## Acceptance and test procedure

`AC-WBS-4.8-01`: the database and every repository port resolve from
generated keep-alive providers in `lib/app/di/`; one override swaps
the store for the entire graph; startup warm-up fails fast on a broken
graph.

`TEST-WBS-4.8-01`: `di_graph_test.dart` in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `4.8` Done; remaining before the
  `4.10` foundation gate: `1.8` (guard profile raise) and `4.9`/`4.10`
  review items.
