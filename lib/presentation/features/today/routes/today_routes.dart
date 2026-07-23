import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/today/screens/today_screen.dart';

/// The Today (home) branch of the tab shell (WBS 5.7.2). Registered by
/// `app_router` so the router composes a route registry, never a feature screen.
List<RouteBase> todayBranchRoutes() => <RouteBase>[
  GoRoute(
    path: RoutePaths.home,
    name: RouteNames.home,
    builder: (context, state) => const TodayScreen(),
  ),
];
