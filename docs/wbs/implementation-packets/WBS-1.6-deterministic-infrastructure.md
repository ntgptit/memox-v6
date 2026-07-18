# WBS 1.6 — Deterministic infrastructure implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Platform / Core infrastructure |
| Depends on | `1.3` — Done |
| Decision gates | ADR-003 (deterministic scheduling), ADR-005 |
| Acceptance | `AC-WBS-1.6-01` |
| Test | `TEST-WBS-1.6-01` |

## Canonical inputs

- `docs/architecture/adr/ADR-003-learning-session-and-scheduling.md` (UTC
  deterministic contract, injected clock).
- WBS §5.2 Drift contract: instants stored UTC through an injected
  clock/timezone boundary; stable IDs and idempotency keys for create-card,
  start-session, attempt, finalize, projection and import.
- WBS 5.5.3: deterministic mode/round shuffle needs a version-stable PRNG —
  `dart:math` `Random(seed)` output is not guaranteed stable across SDKs, so
  the shuffle primitive implements its own generator.
- Approved packages from WBS 1.1: `clock`, `uuid` (`timezone` stays unused
  until Goal/Streak local-day work in 7.x).

## Scope

Create:

- `lib/core/time/app_clock.dart` — `AppClock` port (`nowUtc()`) and
  `SystemClock` implementation backed by `package:clock` (composes with
  `withClock` in tests) that always returns UTC.
- `lib/core/ids/id_generator.dart` — `IdGenerator` port (`newId()`) and
  `UuidIdGenerator` producing time-ordered UUID v7 strings for stable,
  index-friendly primary keys.
- `lib/core/ids/idempotency_key.dart` — pure `buildIdempotencyKey(parts)`:
  deterministic, collision-safe joining (length-prefixed escaping) of stable
  string parts into one retry-stable key.
- `lib/core/random/deterministic_random.dart` — `DeterministicRandom`
  (xorshift64* PRNG, version-stable by construction) and
  `deterministicShuffle<T>(items, seed)` returning a new list via
  Fisher–Yates.
- `test/support/fake_clock.dart` — mutable `FakeClock` implementing
  `AppClock` with `advance(...)` (WBS 1.10 expands the shared harness).
- Tests: `test/core/time/app_clock_test.dart`,
  `test/core/ids/id_generator_test.dart`,
  `test/core/ids/idempotency_key_test.dart`,
  `test/core/random/deterministic_random_test.dart`.

Out of scope: Riverpod providers/DI for these ports (1.11/4.8), the timezone
local-day boundary (7.x with `package:timezone`), session seed policy (5.5.3),
persisted key columns (4.x).

## Exact symbols

| Symbol | File | Contract |
| --- | --- | --- |
| `abstract interface class AppClock { DateTime nowUtc(); }` | `app_clock.dart` | Every time read in domain/data flows through this port. |
| `final class SystemClock implements AppClock` | `app_clock.dart` | `clock.now().toUtc()`; const-constructible. |
| `abstract interface class IdGenerator { String newId(); }` | `id_generator.dart` | Every persisted primary key flows through this port. |
| `final class UuidIdGenerator implements IdGenerator` | `id_generator.dart` | UUID v7 (time-ordered) strings. |
| `String buildIdempotencyKey(List<String> parts)` | `idempotency_key.dart` | Deterministic; distinct part lists never collide; rejects empty input. |
| `final class DeterministicRandom` (`nextInt(maxExclusive)`) | `deterministic_random.dart` | xorshift64* seeded PRNG; identical sequence for identical seed, on every platform/SDK. |
| `List<T> deterministicShuffle<T>(List<T> items, int seed)` | `deterministic_random.dart` | Pure Fisher–Yates; input list untouched; stable for identical seed. |
| `final class FakeClock implements AppClock` | `test/support/fake_clock.dart` | Settable instant + `advance(Duration)`. |

Dependency direction: `core/*` imports Dart SDK + approved util packages only
— no Flutter, no Riverpod, no data/presentation.

## State matrix

| Case | Expected |
| --- | --- |
| `SystemClock.nowUtc()` | Always `isUtc == true` |
| `FakeClock` advance | Deterministic instants for schedule tests |
| Same idempotency parts, retried | Identical key |
| `['ab','c']` vs `['a','bc']` | Different keys (no naive-join collision) |
| Empty parts / empty part list | `ArgumentError` |
| Same shuffle seed | Identical order, original list unchanged |
| Different shuffle seed | Different order (probabilistic, asserted on fixture) |
| `DeterministicRandom(seed)` | Pinned known-answer sequence in test (cross-release regression lock) |

## Acceptance and test procedure

`AC-WBS-1.6-01` is true only when:

1. All four ports/primitives exist as pure Dart with no Flutter/Riverpod
   imports.
2. UUID v7, idempotency and shuffle outputs are deterministic where the
   contract demands and unique where identity demands.
3. The PRNG sequence is locked by a known-answer test so an SDK upgrade
   cannot silently change persisted shuffle orders.
4. Full canonical gate passes.

`TEST-WBS-1.6-01`:

- Clock: system clock returns UTC; fake clock advances deterministically.
- IDs: v7 format/uniqueness/monotonic-prefix sanity.
- Idempotency: determinism, collision resistance, argument validation.
- Random/shuffle: known-answer PRNG sequence, seed determinism, input
  immutability, empty/single-element edge cases.
- Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Success: record register evidence, mark `1.6` Done, then assess `1.7` and
  `1.9` for the next packets.
