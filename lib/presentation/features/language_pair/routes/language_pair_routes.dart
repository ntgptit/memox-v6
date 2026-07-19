import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/language_pair/screens/first_run_language_screen.dart';

/// Language Pair feature routes (WBS 5.1.2), composed by `app_router`.
List<GoRoute> languagePairRoutes() {
  return [
    GoRoute(
      path: RoutePaths.firstRunLanguage,
      name: RouteNames.firstRunLanguage,
      builder: (context, state) => const FirstRunLanguageScreen(),
    ),
  ];
}
