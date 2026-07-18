# ADR-005 — Bootstrap and error boundary

- Status: **Accepted**
- Owner: Platform
- Accepted: 2026-07-18

## Decision

`main.dart` delegates to a small bootstrap. Bootstrap initializes the Flutter
binding, Tier-1 platform configuration, database, dependency overrides,
`ProviderScope`, app widget, lifecycle hooks, and top-level error capture.

Domain/data/platform failures map to typed application failures before reaching
presentation. Logs are structured and redacted. User-visible recovery copy is
localized. Crash reporting or behavioral analytics remains disabled unless a
separate privacy/consent decision enables it.

## Verification

Bootstrap tests cover dependency failure, database failure, uncaught Flutter and
platform async errors, redaction, safe restart, and test overrides. No bootstrap
test requires network access.
