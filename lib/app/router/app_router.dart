import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/app/router/app_tab_shell.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/presentation/features/today/routes/today_routes.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';
import 'package:memox_v6/presentation/features/flashcard/routes/flashcard_routes.dart';
import 'package:memox_v6/presentation/features/language_pair/routes/language_pair_routes.dart';
import 'package:memox_v6/presentation/features/search/routes/search_routes.dart';
import 'package:memox_v6/presentation/features/study/routes/study_routes.dart';

/// Builds a fresh router. Production resolves it through
/// `appRouterInstanceProvider` (which supplies the first-run gate); tests
/// call this directly for isolation.
///
/// Feature route registries (`presentation/features/<feature>/routes/`) are
/// composed here as their owning features land; this file never imports
/// feature screens directly.
///
/// Shape: the four root destinations sit inside one [StatefulShellRoute] so
/// the bottom navigation is persistent and each tab keeps its own stack.
/// Everything that is meant to cover the tab bar — the first-run wizard,
/// deck detail, the Card Editor — stays top-level.
/// [initialLocation] lets a harness mount one destination inside the real
/// shell composition — a screen's chrome is part of what it must look like,
/// so parity gates enter here rather than instantiating a screen bare.
GoRouter createAppRouter({
  Future<bool> Function()? needsFirstRun,
  String initialLocation = RoutePaths.home,
}) {
  // Tier-1 Web requires every canonical destination to keep a refresh-safe
  // URL. Our imperative pushes target declared, deep-linkable GoRoutes, so the
  // browser must reflect the top route instead of retaining its parent URL.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: initialLocation,
    // First-run gate (navigation README: fresh install goes to the
    // Language Pair setup deterministically). Only the home entry
    // redirects; the gate answers whether onboarding is still owed.
    redirect: (context, state) async {
      if (needsFirstRun == null) return null;
      if (state.matchedLocation != RoutePaths.home) return null;
      return await needsFirstRun() ? RoutePaths.firstRunLanding : null;
    },
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppTabShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: todayBranchRoutes()),
          StatefulShellBranch(routes: libraryBranchRoutes()),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.stats,
                name: RouteNames.stats,
                builder: (context, state) => const StatsPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
      ...languagePairRoutes(),
      ...firstRunDeckRoutes(),
      ...deckDetailRoutes(),
      ...flashcardRoutes(),
      ...studyRoutes(),
      ...searchRoutes(),
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
}
