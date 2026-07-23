import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_lifecycle_viewmodel.g.dart';

/// The decks a card can move into (WBS 6.5; `move-flashcard.md`) — Empty/Leaf
/// decks in the card's pair, excluding its current deck. One-shot read.
@riverpod
Future<List<Deck>> cardMoveDestinations(Ref ref, {required String cardId}) {
  return ref.watch(moveFlashcardUseCaseProvider).destinationsFor(cardId);
}

/// Hide/show and delete commands for a card (WBS 6.5; `hide-flashcard.md`,
/// `delete-flashcard.md`). The Leaf list is a stream, so it reflects the
/// change without an explicit invalidate; the store keeps each op atomic.
///
/// Kept alive because the caller only `read`s it (no widget watches its
/// state) — autoDispose would otherwise tear it down mid-command and the
/// pending `state=` would throw.
@Riverpod(keepAlive: true)
class CardLifecycleCommandViewmodel extends _$CardLifecycleCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> setCardHidden({
    required String cardId,
    required bool hidden,
  }) async {
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref
          .read(hideFlashcardUseCaseProvider)
          .setHidden(cardId, hidden: hidden);
    });
  }

  Future<void> deleteCard({required String cardId}) async {
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref.read(deleteFlashcardUseCaseProvider).deleteCard(cardId);
    });
  }

  Future<void> moveCard({
    required String cardId,
    required String targetDeckId,
  }) async {
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref
          .read(moveFlashcardUseCaseProvider)
          .call(cardId: cardId, targetDeckId: targetDeckId);
    });
  }
}
