import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';

/// The active study session route (WBS 5.6). Top-level, full-screen: it covers
/// the tab bar and dispatches to the current stage's mode screen.
List<GoRoute> studyRoutes() {
  return [
    GoRoute(
      path: RoutePaths.study,
      name: RouteNames.study,
      builder: (context, state) => const StudySessionScreen(),
    ),
  ];
}
