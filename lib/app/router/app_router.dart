import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';
import 'package:memox_v6/presentation/features/language_pair/routes/language_pair_routes.dart';

/// Builds a fresh router; production uses the shared [appRouter] instance,
/// tests call this directly for isolation.
///
/// Feature route registries (`presentation/features/<feature>/routes/`) are
/// composed here as their owning features land; this file never imports
/// feature screens directly.
GoRouter createAppRouter({Future<bool> Function()? needsFirstRun}) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    // First-run gate (navigation README: fresh install goes to the
    // Language Pair setup deterministically). Only the home entry
    // redirects; the gate answers whether onboarding is still owed.
    redirect: (context, state) async {
      if (needsFirstRun == null) return null;
      if (state.matchedLocation != RoutePaths.home) return null;
      return await needsFirstRun() ? RoutePaths.firstRunLanding : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
      ...languagePairRoutes(),
      ...deckRoutes(),
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
}

/// Single production router instance consumed by `MemoxApp`.
final GoRouter appRouter = createAppRouter();
