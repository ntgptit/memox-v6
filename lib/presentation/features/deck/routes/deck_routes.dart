import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_landing_screen.dart';

/// Deck feature routes (WBS 5.2.3+), composed by `app_router`.
List<GoRoute> deckRoutes() {
  return [
    GoRoute(
      path: RoutePaths.firstRunLanding,
      name: RouteNames.firstRunLanding,
      builder: (context, state) => const FirstRunLandingScreen(),
    ),
  ];
}
