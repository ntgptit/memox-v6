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
