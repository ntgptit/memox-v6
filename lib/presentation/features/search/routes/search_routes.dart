import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/search/screens/search_screen.dart';

/// Library search route (WBS 10.2), composed by `app_router`. Top-level: a
/// pushed full-screen surface over the tab bar, returning through its app bar.
List<GoRoute> searchRoutes() {
  return [
    GoRoute(
      path: RoutePaths.search,
      name: RouteNames.search,
      builder: (context, state) => const SearchScreen(),
    ),
  ];
}
