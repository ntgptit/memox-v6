# WBS 1.3 — App bootstrap implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Platform / Bootstrap |
| Depends on | `1.1` — Done |
| Decision gates | DG-02 (ADR-002), ADR-005 |
| Acceptance | `AC-WBS-1.3-01` |
| Test | `TEST-WBS-1.3-01` |

## Canonical inputs

- `docs/architecture/adr/ADR-005-bootstrap-and-error-boundary.md`.
- `docs/architecture/adr/ADR-007-riverpod-and-testing.md`.
- Guard rules `memox.observability.error_pipeline_completeness` (the file
  `lib/app/bootstrap/app_bootstrap.dart` must wire both `FlutterError.onError`
  and `runZonedGuarded`) and `memox.observability.error_zone_ownership`
  (global handlers only inside `lib/app/bootstrap/**`).
- Guard rule `memox.observability.no_debug_print`: no `print`/`debugPrint`/
  `developer.log` in `lib/`; until WBS 1.5 delivers `AppLogger`, the only
  approved default error sink is `FlutterError.presentError`.
- Existing `lib/main.dart` starter app and `lib/l10n/app_en.arb` / `app_vi.arb`.

## Scope

Create:

- `lib/app/app.dart` — `MemoxApp` root widget: `MaterialApp` with localized
  title, l10n delegates/locales, default `ThemeData` and a minimal localized
  home scaffold. No business logic, no raw visual values beyond framework
  defaults (theme tokens are owned by WBS 2.x; the real home route by 1.4/5.x).
- `lib/app/bootstrap/app_bootstrap.dart` — `bootstrap(...)` composition entry:
  `runZonedGuarded` error zone, `FlutterError.onError` +
  `PlatformDispatcher.instance.onError` wiring, root `AppLifecycleListener`,
  `ProviderScope` with test-override seam, `runApp`. Uncaught errors map to
  `FlutterErrorDetails` and route to one injectable reporter (default
  `FlutterError.presentError`).
- `test/app/app_test.dart` — root widget renders the localized home in en/vi.
- `test/app/bootstrap/app_bootstrap_test.dart` — handler installation, platform
  and zone error mapping to the reporter, lifecycle callback delivery and
  handler restoration.

Modify:

- `lib/main.dart` — reduce to only the `bootstrap()` call.
- `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` — drop the starter counter
  strings (`pushCounterMessage`, `incrementTooltip`); keep `appTitle`,
  `homeTitle`.

Delete:

- `test/widget_test.dart` (starter counter test superseded by the tests above).

Generated (never edit): `lib/l10n/generated/**`.

Out of scope: router/navigation (1.4), typed `AppFailure` mapping, redacted
logger and user-visible error surfaces (1.5), clock/ID ports (1.6), database
(4.1), theme/tokens (2.x), any feature UI.

## Exact symbols

| Symbol | File | Contract |
| --- | --- | --- |
| `Future<void> bootstrap({List<Override> overrides, BootstrapErrorReporter? onError, BootstrapLifecycleObserver? onLifecycleStateChanged})` | `app_bootstrap.dart` | Sole composition entry; awaits `runZonedGuarded`; no return of internals. |
| `typedef BootstrapErrorReporter = void Function(FlutterErrorDetails)` | `app_bootstrap.dart` | Single sink for framework/platform/zone errors; WBS 1.5 rewires it to `AppLogger`. |
| `typedef BootstrapLifecycleObserver = void Function(AppLifecycleState)` | `app_bootstrap.dart` | Lifecycle seam consumed later by session checkpointing. |
| `@visibleForTesting installGlobalErrorHandlers`, `installLifecycleListener`, `buildRoot`, `detailsForUncaughtError` | `app_bootstrap.dart` | Test seams; only `bootstrap` is production API. |
| `class MemoxApp extends StatelessWidget` | `app.dart` | Root `MaterialApp`; imports domain/data/platform nothing. |

Dependency direction: `main.dart → app/bootstrap → app/app.dart`; no other
source imports the bootstrap file.

## State/error matrix

| Case | Expected |
| --- | --- |
| Uncaught build/layout error | `FlutterError.onError` → reporter with original details |
| Uncaught platform-dispatcher async error | mapped `FlutterErrorDetails`, reporter called, handler returns `true` |
| Uncaught zone error | mapped `FlutterErrorDetails` with stack, reporter called |
| Lifecycle transition (resumed/inactive/paused/…) | observer callback receives each state exactly once |
| Test overrides supplied | `ProviderScope` receives them; no global mutable DI |
| No reporter/observer supplied | defaults active (`FlutterError.presentError`; lifecycle no-op) — app still boots |

## Acceptance and test procedure

`AC-WBS-1.3-01` is true only when:

1. `lib/main.dart` contains only the bootstrap delegation (no widgets, no
   handlers, no configuration).
2. `app_bootstrap.dart` wires `runZonedGuarded`, `FlutterError.onError`,
   `PlatformDispatcher.instance.onError`, `AppLifecycleListener`,
   `ProviderScope` and `runApp`, and is the only `lib/` file assigning global
   handlers.
3. All uncaught error paths converge on one reporter seam; no banned logging
   call anywhere in `lib/`.
4. Root widget renders the localized home in en and vi with zero hardcoded UI
   strings.
5. The full canonical gate passes.

`TEST-WBS-1.3-01`:

- `test/app/bootstrap/app_bootstrap_test.dart`: reporter receives framework
  error via installed `FlutterError.onError`; platform handler maps and
  returns `true`; `detailsForUncaughtError` preserves error and stack;
  lifecycle observer fires on `handleAppLifecycleStateChanged`; original
  handlers restored after each test.
- `test/app/app_test.dart`: `buildRoot()` pumps; localized home title visible
  under en and vi locales.
- Run once through `node tool/verify/run.mjs` (format, l10n, codegen, guard,
  analyze, tests). No loose commands.
- Fixtures: none beyond flutter_test binding; no network, no database.

## Failure and completion

- Guard conflict: fix the code; never widen `error_zone_ownership` scope.
- Success: record register evidence, mark `1.3` Done, then assess `1.4`,
  `1.5`, `1.6` and `1.9` for packet authoring in dependency order.
