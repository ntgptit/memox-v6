# ADR-004 — Local persistence on Web and Android

- Status: **Accepted**
- Owner: Data / Platform
- Accepted: 2026-07-18
- Decision gate: DG-06

## Decision

Drift is the local canonical store. Web and Android share one logical schema,
constraints, migrations, repository contracts, and transaction semantics. Each
platform uses a tested opener behind the database composition boundary.

Android opens SQLite off the main isolate where supported. Web uses the approved
Drift web/Wasm-compatible opener selected during dependency baseline. Platform
differences must not leak into domain or presentation.

## Consequences

- Schema version and policy version are independent.
- Every write command declares transaction and idempotency boundaries.
- Unsupported storage capability fails at bootstrap with a typed, user-safe
  recovery result; it never silently falls back to provider memory.

## Verification

Run the same repository/DAO contract suite against both Tier-1 openers, plus
migration, restart, transaction rollback, concurrent writer, quota/low-storage,
and corrupted-store recovery tests. See [`../../database/README.md`](../../database/README.md).
