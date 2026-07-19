# WBS 1.10 — Shared test infrastructure implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | QA / Developer experience |
| Depends on | `1.1–1.7` — Done |
| Decision gates | — |
| Acceptance | `AC-WBS-1.10-01` |
| Test | `TEST-WBS-1.10-01` |

## Canonical inputs

- WBS 1.10: fake clock/IDs/random/repos, ProviderContainer overrides,
  in-memory Drift, Tier-1 opener contract harness, widget/golden
  wrappers and restart/E2E fixtures.
- Ports already injectable: `AppClock`, `IdGenerator`,
  `DeterministicRandom`; `localizedApp`/`FakeClock`/l10n fixtures
  landed with 1.9.

## Scope (`test/support/`)

- `fake_clock.dart` (1.9) + `sequential_ids.dart` — deterministic
  clock and `id-N` generator over the injected ports;
  `DeterministicRandom` in `lib/core/random` is already seeded and
  test-usable as is.
- `test_container.dart` — `createTestContainer(overrides:)` returning a
  `ProviderContainer` auto-disposed by the current test; the standard
  entry for provider-level tests once the 4.8 DI graph lands.
- `database_contract.dart` — `runDatabaseLifecycleContract(name,
  buildExecutor)`: the Tier-1 opener contract as a reusable group
  (schema v1 + queries, FK enforcement, idempotent close). Unit tests
  run it over `NativeDatabase.memory`; the Tier-1 platform smoke
  (5.7.4/16.1) runs the same group over the real Android/Web openers.
- `restart_harness.dart` — `RestartHarness` backing the database with a
  temp file: `restart()` closes the instance and reopens the same
  store, replaying a process restart (E2E resume fixtures build on
  this).
- `localized_app.dart` (1.9) stays the widget wrapper; the committed
  responsive golden suite (2.x) remains the golden harness.
- **Fake-repository policy**: the preferred repository fixture is the
  real Drift implementation over an in-memory executor (proven across
  the 4.4/4.6 suites — fast and honest). Hand-written in-memory fakes
  are added only when a consumer needs stream/timing control a real
  store cannot give; none exist yet by design.
- `test_support_test.dart` — the harness proves itself: deterministic
  ids, override + auto-dispose containers, the opener contract over
  the in-memory executor, and fixture data surviving a simulated
  restart (seeded via 1.7 `DevFixtures`).

## Acceptance and test procedure

`AC-WBS-1.10-01`: deterministic clock/ids/random are injectable
everywhere; provider tests get an auto-disposed container helper; the
opener contract is a single reusable harness; restart fixtures replay
close/reopen on a real store; the fake-repo policy is recorded.

`TEST-WBS-1.10-01`: `test_support_test.dart` in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `1.10` Done; `1.11` (Riverpod
  foundation) is next, unblocking `4.8`.
