# ADR-007 — Riverpod DI and deterministic testing

- Status: **Accepted**
- Owner: Architecture / QA
- Accepted: 2026-07-18

## Decision

Providers use Riverpod Annotation and generated code. App-wide infrastructure
providers are intentionally keep-alive; screen/query families use stable keys
and auto-dispose by default. Presentation commands depend on use cases, not
repository providers. UI watches state while callbacks use `ref.read`.

Clock, timezone, ID/idempotency, shuffle/random, repositories, platform
capabilities, and database openers are injectable and overrideable in
`ProviderContainer`/`ProviderScope` tests. Async state uses the shared MemoX
loading/data/error/retry contract. Cancellation/disposal uses `ref.onDispose`
and post-await liveness uses `ref.mounted`.

## Verification

The shared test harness supplies fake clock/IDs/random, fake repositories,
in-memory Drift for repository tests, Tier-1 opener contract tests, provider
override helpers, localized widget wrappers, golden fixtures, and restart/E2E
fixtures. Generated files are regenerated and never edited or committed.
