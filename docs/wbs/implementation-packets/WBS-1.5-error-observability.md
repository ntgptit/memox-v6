# WBS 1.5 — Error and observability pipeline implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Platform / Observability |
| Depends on | `1.3` — Done |
| Decision gates | ADR-005 |
| Acceptance | `AC-WBS-1.5-01` |
| Test | `TEST-WBS-1.5-01` |

## Canonical inputs

- `docs/architecture/adr/ADR-005-bootstrap-and-error-boundary.md`.
- Guard observability rules: `no_debug_print` (raw logging only inside
  `lib/core/logging/app_logger.dart`), `no_sensitive_log_payload` (no
  token/password/secret/cookie/session/credential/api-key/bearer values in log
  calls), `no_direct_sentry_calls`, `error_zone_ownership` (handler
  assignment only in `lib/app/bootstrap/**`).
- Guard error-handling rules: failures map to `AppFailure`; UI never
  stringifies raw errors; no `throw Exception(...)`.
- WBS 1.3 bootstrap reporter seam.

## Scope

Create:

- `lib/core/errors/app_failure.dart` — sealed `AppFailure` taxonomy baseline:
  `UnexpectedFailure` plus the `AppFailure.from(error, stackTrace)` boundary
  mapper (identity for existing failures). Later waves extend the sealed
  library with domain variants.
- `lib/core/logging/redaction.dart` — pure `redactSensitive(String)` masking
  secret-keyed values and bearer tokens.
- `lib/core/logging/app_logger.dart` — `AppLogger` with
  `debug/info/warning/error/fatal`, structured `LogRecord`, redaction applied
  to every message/context value, injectable `LogSink` (default:
  `dart:developer` log inside this file only, the guard-approved location).
- `test/core/errors/app_failure_test.dart`,
  `test/core/logging/redaction_test.dart`,
  `test/core/logging/app_logger_test.dart`.

Modify:

- `lib/app/bootstrap/app_bootstrap.dart` — default reporter now routes
  uncaught errors through `AppLogger.fatal` (redacted) and presents details in
  debug via `FlutterError.presentError`; wire `ErrorWidget.builder` to a
  user-safe localized build-failure surface (icon-only fallback when
  localizations are unavailable at the failure point).
- `lib/l10n/app_en.arb` / `app_vi.arb` — add `somethingWentWrongMessage`.
- `test/app/bootstrap/app_bootstrap_test.dart` — cover the new default
  pipeline and safe error widget.

Generated (never edit): `lib/l10n/generated/**`.

Out of scope: crash reporting/analytics (explicitly disabled per ADR-005
pending a consent decision), data-layer failure variants (4.x), provider
error surfaces and `MxActionErrors` (3.9), retry UX (feature waves).

## Exact symbols

| Symbol | File | Contract |
| --- | --- | --- |
| `sealed class AppFailure implements Exception` (`message`, `cause`, `stackTrace`) | `app_failure.dart` | Base of every application failure; presentation never sees low-level exceptions. |
| `final class UnexpectedFailure extends AppFailure` | `app_failure.dart` | Fallback wrapper preserving cause and stack. |
| `AppFailure AppFailure.from(Object error, StackTrace stackTrace)` | `app_failure.dart` | Identity for `AppFailure`, otherwise `UnexpectedFailure`. |
| `String redactSensitive(String input)` | `redaction.dart` | Masks `key: value`/`key=value` secrets and bearer tokens with `[REDACTED]`. |
| `enum LogLevel { debug, info, warning, error, fatal }` | `app_logger.dart` | Ordered severity. |
| `final class LogRecord` (`level`, `message`, `error`, `stackTrace`, `context`) | `app_logger.dart` | Immutable structured record; message/context already redacted. |
| `abstract final class AppLogger` (`debug/info/warning/error/fatal`, `@visibleForTesting sink`) | `app_logger.dart` | Sole logging API; sink injectable for tests, default `dart:developer`. |

Dependency direction: `app/bootstrap → core/logging + core/errors`; core files
import Flutter foundation only (no Riverpod, no data, no features).

## State/error matrix

| Case | Expected |
| --- | --- |
| Uncaught framework/platform/zone error, no custom reporter | `AppLogger.fatal` record with redacted message, original error and stack |
| Custom reporter injected (tests) | Custom reporter wins; logger untouched |
| Log message/context containing `password=...`, `token: ...`, `Bearer x` | Persisted record shows `[REDACTED]` |
| Widget build failure in release surface | Safe error widget; localized message when l10n reachable, icon-only otherwise; never the framework grey/red dump |
| `AppFailure.from` on an `AppFailure` | Same instance returned |
| `AppFailure.from` on any other error | `UnexpectedFailure` with cause and stack preserved |

## Acceptance and test procedure

`AC-WBS-1.5-01` is true only when:

1. `AppFailure`/`UnexpectedFailure`/`from` exist as the single failure
   taxonomy root and compile with no Flutter dependency beyond core.
2. `AppLogger` is the only file calling raw log primitives; every emitted
   record passes redaction.
3. Bootstrap's default pipeline routes all three capture paths
   (framework/platform/zone) into `AppLogger.fatal` and `ErrorWidget.builder`
   is assigned inside the bootstrap file only.
4. The safe error surface shows localized copy from ARB (en/vi) when
   available and degrades to a non-textual surface otherwise.
5. Full canonical gate passes.

`TEST-WBS-1.5-01`:

- `app_failure_test.dart`: identity mapping, wrapping, message/cause/stack
  preservation.
- `redaction_test.dart`: masks password/token/secret/api-key/bearer values,
  leaves ordinary text untouched.
- `app_logger_test.dart`: sink receives records at each level; redaction
  applied to message and context; sink restore.
- `app_bootstrap_test.dart`: default reporter emits a fatal record through an
  injected sink; custom reporter bypasses the logger; `ErrorWidget.builder`
  assigned by handler installation renders the safe surface.
- Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Guard conflict: fix code; never extend `no_debug_print` excludes.
- Success: record register evidence, mark `1.5` Done, then assess `1.6` and
  `1.9` for the next packets.
