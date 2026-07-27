import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/move_destination.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_detail_viewmodel.g.dart';

/// Open-deck state (WBS 5.2.4B). The screen derives Empty/Leaf/Parent
/// from the two reactive content streams; a stored mode never exists.

@riverpod
Future<Deck?> deckDetail(Ref ref, {required String deckId}) {
  return ref.watch(openDeckUseCaseProvider).deckById(deckId);
}

@riverpod
Stream<List<Deck>> deckChildren(Ref ref, {required String deckId}) {
  return ref.watch(openDeckUseCaseProvider).childrenOf(deckId);
}

/// The Parent branch's child rows, with the same counters the Library root
/// shows (WBS 5.4.2 read model on the deck-detail scope).
@riverpod
Stream<List<DeckSummary>> deckChildSummaries(
  Ref ref, {
  required String deckId,
}) {
  return ref.watch(openDeckUseCaseProvider).childSummariesOf(deckId);
}

@riverpod
Stream<List<Flashcard>> deckCards(Ref ref, {required String deckId}) {
  return ref.watch(openDeckUseCaseProvider).cardsOf(deckId);
}

/// Aggregate active-card count of the subtree (`open-deck.md` §5
/// Parent summary). Re-fetches when the direct child list changes;
/// deep-descendant card changes refresh on the next visit (recorded
/// boundary).
@riverpod
Future<int> deckSubtreeCards(Ref ref, {required String deckId}) async {
  await ref.watch(deckChildrenProvider(deckId: deckId).future);
  return ref.watch(openDeckUseCaseProvider).subtreeCardCount(deckId);
}

/// The ancestor chain for the breadcrumb (WBS 6.2), ordered root → … → the
/// deck itself. Re-reads when the deck record changes (a move reparents it).
@riverpod
Future<List<Deck>> deckBreadcrumb(Ref ref, {required String deckId}) async {
  await ref.watch(deckDetailProvider(deckId: deckId).future);
  return ref.watch(openDeckUseCaseProvider).ancestorsOf(deckId);
}

/// Every deck the move picker lists for [deckId] (WBS 6.2), each carrying the
/// reason it cannot be chosen when it cannot. Reads the moving deck for its
/// language pair first.
///
/// Candidates rather than only the eligible ones: `move-deck.md` §3 disables
/// an ineligible destination with a helper rather than hiding it.
@riverpod
Future<List<MoveDestination>> deckMoveDestinations(
  Ref ref, {
  required String deckId,
}) async {
  final deck = await ref.watch(deckDetailProvider(deckId: deckId).future);
  if (deck == null) return const [];
  return ref
      .watch(moveDeckUseCaseProvider)
      .destinationCandidatesFor(
        deckId: deckId,
        languagePairId: deck.languagePairId,
      );
}
