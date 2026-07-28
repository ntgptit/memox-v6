import 'package:memox_v6/presentation/features/study/screens/mode_picker_screen.dart';
import 'package:memox_v6/app/router/route_params.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';

/// The active study session route (WBS 5.6). Top-level, full-screen: it covers
/// the tab bar and dispatches to the current stage's mode screen.
List<GoRoute> studyRoutes() {
  return [
    GoRoute(
      path: RoutePaths.practicePattern,
      name: RouteNames.practice,
      builder: (context, state) => ModePickerScreen(
        deckId: state.pathParameters[RouteParams.deckId] ?? '',
      ),
    ),
    GoRoute(
      path: RoutePaths.study,
      name: RouteNames.study,
      builder: (context, state) => const StudySessionScreen(),
    ),
  ];
}
