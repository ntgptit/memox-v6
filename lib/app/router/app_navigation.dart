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
  /// Back walks up one level). The future completes when that branch is
  /// popped, so a caller can refresh what it handed off
  /// (`open-search-result.md` §4).
  Future<void> pushDeckDetail(String deckId) =>
      GoRouter.of(this).push(RoutePaths.deckDetail(deckId));

  /// Opens Library search (WBS 10.2). Completes when search is popped, so
  /// the caller can refresh what search may have mutated on the way back
  /// (`refresh-today-projections.md` §3, "Deck/Card mutation").
  Future<void> pushSearch() => GoRouter.of(this).push(RoutePaths.search);

  /// Pushes the Card Editor for creating a card in [deckId]. Completes when
  /// the editor is popped, so the caller can refresh what it handed off
  /// (`manage-today-create-actions.md` §6).
  Future<void> pushNewCard(String deckId) =>
      GoRouter.of(this).push(RoutePaths.newCard(deckId));

  /// Opens the Card Editor in edit mode for an existing card (WBS 6.3).
  /// Completes when the editor is popped, so the caller can refresh.
  /// Opens the Card Detail read projection (`view-card-detail.md`). Pushed:
  /// the return preserves whatever list sent the learner here, which is what
  /// `open-search-result.md` §3's "Return preserves Search" asks for.
  /// Opens the Practice mode picker for a deck (`study-deck.md` §4). Pushed:
  /// §6 makes it a selection surface, so Back returns to the deck rather than
  /// leaving a session behind.
  Future<void> pushPractice(String deckId) =>
      GoRouter.of(this).push(RoutePaths.practice(deckId));

  Future<void> pushCardDetail(String deckId, String cardId) =>
      GoRouter.of(this).push(RoutePaths.cardDetail(deckId, cardId));

  Future<void> pushEditCard(String deckId, String cardId) =>
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
