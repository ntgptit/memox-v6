# WBS 1.4 — Router skeleton implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Platform / Navigation |
| Depends on | `1.1` — Done (`1.3` also Done) |
| Decision gates | ADR-006 (navigation contract), DG-02 |
| Acceptance | `AC-WBS-1.4-01` |
| Test | `TEST-WBS-1.4-01` |

## Canonical inputs

- `docs/architecture/adr/ADR-006-navigation-contract.md`.
- Guard routing rules: `no_route_definition_outside_router` (GoRoute only in
  `lib/app/router/app_router.dart` or feature `routes/*_routes.dart`),
  `no_raw_route_path_string` / `no_raw_route_name_string` /
  `no_raw_route_param_key` (raw strings only in `route_paths.dart`,
  `route_names.dart`, `app_router.dart`, `app_navigation.dart`,
  `redirect.dart`, `route_placeholder.dart`),
  `use_shared_navigation_extension` (UI navigates via the shared
  `BuildContext` extension only), `no_raw_navigator_push`,
  `app_router_no_feature_screen_imports`.
- `go_router ^17.3.0` from the WBS 1.1 baseline.
- Existing `lib/app/app.dart` root widget from WBS 1.3.

## Scope

Create:

- `lib/app/router/route_names.dart` — `RouteNames` constants (home; not-found
  copy key is l10n, not a route).
- `lib/app/router/route_paths.dart` — `RoutePaths` constants (`/`).
- `lib/app/router/route_placeholder.dart` — localized placeholder screens for
  skeleton routes: home placeholder and unknown-route (not-found) screen.
- `lib/app/router/app_router.dart` — `createAppRouter()` + shared `appRouter`
  instance: initial location, home `GoRoute`, `errorBuilder` → not-found. No
  feature screen imports (none exist yet).
- `lib/app/router/app_navigation.dart` — `AppNavigation` extension on
  `BuildContext` (`goHome()`); the only file allowed to touch raw GoRouter
  navigation APIs.
- `test/app/router/app_router_test.dart` — constants, initial route, unknown
  path, extension navigation.

Modify:

- `lib/app/app.dart` — switch to `MaterialApp.router(routerConfig: appRouter)`;
  remove the WBS 1.3 inline home placeholder (moves to
  `route_placeholder.dart`).
- `lib/l10n/app_en.arb` / `app_vi.arb` — add `routeNotFoundMessage`.

Generated (never edit): `lib/l10n/generated/**`.

Out of scope: `ShellRoute`/`AppShell` with bottom navigation (owned by WBS
3.5/3.6 with the `Mx*` shells), redirects/guards (feature waves), feature route
registries themselves (each feature adds `presentation/features/<f>/routes/`
when it lands and `app_router.dart` composes it), typed navigation effects
(1.11), deep-link/session precedence tests (5.6/5.7 per ADR-006).

## Exact symbols

| Symbol | File | Contract |
| --- | --- | --- |
| `abstract final class RouteNames { static const String home; }` | `route_names.dart` | Only source of route names. |
| `abstract final class RoutePaths { static const String home; }` | `route_paths.dart` | Only source of route paths. |
| `class HomePlaceholderScreen` / `class RouteNotFoundScreen` | `route_placeholder.dart` | Localized stateless screens; replaced when owning features land. |
| `GoRouter createAppRouter()` | `app_router.dart` | Fresh router per call (tests); route table + errorBuilder. |
| `final GoRouter appRouter` | `app_router.dart` | Single production instance consumed by `MemoxApp`. |
| `extension AppNavigation on BuildContext { void goHome(); }` | `app_navigation.dart` | Sole navigation call-site API for widgets. |

Dependency direction: `app.dart → router/app_router.dart → route_*` ; widgets
→ `app_navigation.dart` only. No feature/data imports anywhere in `lib/app/`.

## State matrix

| Case | Expected |
| --- | --- |
| Launch `/` | Home placeholder with localized title |
| Unknown path (deep link) | Not-found screen, localized message, no crash |
| `context.goHome()` from any screen | Back on home placeholder |
| Rebuild of `MemoxApp` | Same router instance; no route reset |

## Acceptance and test procedure

`AC-WBS-1.4-01` is true only when:

1. All route names/paths live in `RouteNames`/`RoutePaths`; no raw route
   string outside the guard-allowed router files.
2. `MemoxApp` uses `MaterialApp.router` with the shared `appRouter`.
3. Unknown locations render the localized not-found screen.
4. Widgets can navigate only through the `AppNavigation` extension.
5. Full canonical gate passes with zero routing-rule violations.

`TEST-WBS-1.4-01`:

- `test/app/router/app_router_test.dart`: `RoutePaths.home == '/'` and
  `RouteNames.home == 'home'`; initial pump shows the home placeholder in en
  and vi; navigating the router to an unknown location shows
  `routeNotFoundMessage`; `context.goHome()` returns to home.
- Existing `test/app/**` suites keep passing unchanged
  (`buildRoot` still renders the localized home).
- Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Guard routing violation: fix code placement; never extend the raw-string
  exclude lists.
- Success: record register evidence, mark `1.4` Done, then assess `1.5`,
  `1.6`, `1.9` for the next packets in dependency order.
