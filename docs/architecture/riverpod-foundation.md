# Riverpod foundation contract

- Status: **Accepted** (WBS 1.11, 2026-07-19)
- Owner: Architecture
- Enforced by: the `memox` guard ruleset (`memox.state_management.*`)

## Provider rules

1. **Generated only.** Every provider uses `@riverpod`/`@Riverpod`
   codegen; manual `Provider(...)` constructors are guard-rejected in
   `lib/`.
2. **Lifecycle by role.** Infrastructure (clock, ids, database, DAOs,
   repositories, services) is `@Riverpod(keepAlive: true)` and lives in
   `lib/app/di/`. Screen, query, search and input state defaults to
   autoDispose — navigation churn must reclaim it.
3. **Families** parameterize queries; family keys are value-equal
   (ids/records, never mutable objects). A family instance's lifecycle
   follows rule 2.
4. **No provider reads the wall clock, random source or id source
   directly** — always through the injected ports (`appClockProvider`,
   `idGeneratorProvider`), so overrides make every provider
   deterministic.

## Command/effect pattern

- Mutations run through action controllers built on `MxActionRunner`
  (`lib/presentation/shared/viewmodels/`), exposing `AsyncValue<void>`
  action state. UI extracts failures via `MxActionErrors` only.
- Side effects (navigation, snackbars) subscribe with `ref.listen` —
  never inside `build` and never by watching action state imperatively.

## Cancellation, invalidation, retry

- **Cancellation**: async providers must tolerate being invalidated
  mid-flight — a stale computation's result is discarded by Riverpod;
  cleanup hooks register with `ref.onDispose`.
- **Invalidation** is the one refresh mechanism: `ref.invalidate` /
  `ref.invalidateSelf`. Broad `container`-wide invalidation is
  guard-rejected.
- **Retry** is user-triggered invalidation. Providers do not loop
  retries internally; persistence-level retry belongs to repository
  contracts, and the SRS learning-retry namespace is separate by
  design.

## Testing

- Provider tests build on `createTestContainer(overrides: …)`
  (`test/support/test_container.dart`) — auto-disposed, override-first.
- The foundation contract itself is covered by
  `test/app/di/riverpod_foundation_test.dart`: keep-alive persistence,
  override substitution, autoDispose reclamation, mid-flight
  invalidation discarding stale results, and invalidate-as-retry.
