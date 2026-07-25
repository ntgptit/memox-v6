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

  /// Returns to the first-run landing (from the wizard steps).
  void goFirstRunLanding() => GoRouter.of(this).go(RoutePaths.firstRunLanding);

  /// Opens the first-run language step (step 1 of the setup).
  void goFirstRunLanguage() =>
      GoRouter.of(this).go(RoutePaths.firstRunLanguage);

  /// Opens the first-run deck step (step 2 of the setup).
  void goFirstRunDeckSetup() =>
      GoRouter.of(this).go(RoutePaths.firstRunDeckSetup);

  /// Opens the Library root.
  void goLibrary() => GoRouter.of(this).go(RoutePaths.library);

  /// Opens the active study session route (WBS 5.6/5.7).
  void goStudy() => GoRouter.of(this).go(RoutePaths.study);

  /// Opens the Stats root (placeholder until WBS 5.8 lands).
  void goStats() => GoRouter.of(this).go(RoutePaths.stats);

  /// Opens the Profile root (placeholder until account scope lands).
  void goProfile() => GoRouter.of(this).go(RoutePaths.profile);

  /// Opens one deck's detail (replacing the current location).
  void goDeckDetail(String deckId) =>
      GoRouter.of(this).go(RoutePaths.deckDetail(deckId));

  /// Pushes a nested deck onto the browse stack (browse-nested-decks:
  /// Back walks up one level).
  void pushDeckDetail(String deckId) =>
      GoRouter.of(this).push(RoutePaths.deckDetail(deckId));

  /// Opens Library search (WBS 10.2).
  void pushSearch() => GoRouter.of(this).push(RoutePaths.search);

  /// Pushes the Card Editor for creating a card in [deckId].
  void pushNewCard(String deckId) =>
      GoRouter.of(this).push(RoutePaths.newCard(deckId));

  /// Opens the Card Editor in edit mode for an existing card (WBS 6.3).
  void pushEditCard(String deckId, String cardId) =>
      GoRouter.of(this).push(RoutePaths.editCard(deckId, cardId));

  /// Pops one level, falling back to the Library root.
  void backFromDeck() {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(RoutePaths.library);
  }
}
