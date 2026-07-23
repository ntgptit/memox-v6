import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_params.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/presentation/features/flashcard/screens/card_editor_screen.dart';

/// Flashcard feature routes (WBS 5.3.2+), composed by `app_router`.
List<GoRoute> flashcardRoutes() {
  return [
    GoRoute(
      path: RoutePaths.newCardPattern,
      name: RouteNames.newCard,
      builder: (context, state) => CardEditorScreen(
        deckId: state.pathParameters[RouteParams.deckId] ?? '',
      ),
    ),
    GoRoute(
      path: RoutePaths.editCardPattern,
      name: RouteNames.editCard,
      builder: (context, state) => CardEditorScreen(
        deckId: state.pathParameters[RouteParams.deckId] ?? '',
        cardId: state.pathParameters[RouteParams.cardId],
      ),
    ),
  ];
}
