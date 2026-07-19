import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_params.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/deck/screens/deck_detail_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_deck_setup_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/library_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_landing_screen.dart';

/// Deck feature routes (WBS 5.2.3+), composed by `app_router`.
List<GoRoute> deckRoutes() {
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
    GoRoute(
      path: RoutePaths.library,
      name: RouteNames.library,
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: RoutePaths.deckDetailPattern,
      name: RouteNames.deckDetail,
      builder: (context, state) => DeckDetailScreen(
        deckId: state.pathParameters[RouteParams.deckId] ?? '',
      ),
    ),
  ];
}
