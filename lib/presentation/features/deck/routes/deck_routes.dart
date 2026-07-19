import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_params.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/deck/screens/deck_detail_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_deck_setup_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/library_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_landing_screen.dart';

/// Every Deck route in one flat list, for harnesses that mount the
/// feature standalone. Production never uses this: `app_router` composes
/// the three registries below into their proper shell positions.
@visibleForTesting
List<GoRoute> deckRoutes() => [
  ...firstRunDeckRoutes(),
  ...libraryBranchRoutes(),
  ...deckDetailRoutes(),
];

/// First-run wizard steps owned by the Deck feature (WBS 5.2.3).
///
/// Top-level, never inside the tab shell: the wizard is a focused
/// full-screen flow with no bottom navigation (`create-deck.md` §4).
List<GoRoute> firstRunDeckRoutes() {
  return [
    GoRoute(
      path: RoutePaths.firstRunLanding,
      name: RouteNames.firstRunLanding,
      builder: (context, state) => const FirstRunLandingScreen(),
    ),
    GoRoute(
      path: RoutePaths.firstRunDeckSetup,
      name: RouteNames.firstRunDeckSetup,
      builder: (context, state) => const FirstRunDeckSetupScreen(),
    ),
  ];
}

/// The Library root — a tab-shell branch, so it renders under the
/// persistent bottom navigation.
List<GoRoute> libraryBranchRoutes() {
  return [
    GoRoute(
      path: RoutePaths.library,
      name: RouteNames.library,
      builder: (context, state) => const LibraryScreen(),
    ),
  ];
}

/// Deck detail (WBS 5.2.4B). Top-level: a pushed detail surface covers
/// the tab bar and returns through its contextual app bar.
List<GoRoute> deckDetailRoutes() {
  return [
    GoRoute(
      path: RoutePaths.deckDetailPattern,
      name: RouteNames.deckDetail,
      builder: (context, state) => DeckDetailScreen(
        deckId: state.pathParameters[RouteParams.deckId] ?? '',
      ),
    ),
  ];
}
