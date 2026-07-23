import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck.dart';
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
