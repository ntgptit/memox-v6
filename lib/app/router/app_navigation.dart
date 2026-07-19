import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_paths.dart';

/// Shared navigation API for widgets.
///
/// The only file allowed to call raw GoRouter navigation
/// (guard: `memox.routing.use_shared_navigation_extension`).
extension AppNavigation on BuildContext {
  /// Returns to the learning entry (home) route.
  void goHome() => GoRouter.of(this).go(RoutePaths.home);

  /// Opens the first-run language step (step 1 of the setup).
  void goFirstRunLanguage() =>
      GoRouter.of(this).go(RoutePaths.firstRunLanguage);
}
