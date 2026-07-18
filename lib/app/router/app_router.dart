import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';

/// Builds a fresh router; production uses the shared [appRouter] instance,
/// tests call this directly for isolation.
///
/// Feature route registries (`presentation/features/<feature>/routes/`) are
/// composed here as their owning features land; this file never imports
/// feature screens directly.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
}

/// Single production router instance consumed by `MemoxApp`.
final GoRouter appRouter = createAppRouter();
