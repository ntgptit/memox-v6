import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/move_flashcard_result.dart';
import 'package:memox_v6/domain/deck/card_target.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_lifecycle_viewmodel.g.dart';

/// The decks a card can move into (WBS 6.5; `move-flashcard.md`) — Empty/Leaf
/// decks in the card's pair, excluding its current deck. One-shot read.
@riverpod
Future<List<CardTarget>> cardMoveDestinations(
  Ref ref, {
  required String cardId,
}) {
  return ref.watch(moveFlashcardUseCaseProvider).targetCandidatesFor(cardId);
}

/// Hide/show and delete commands for a card (WBS 6.5; `hide-flashcard.md`,
/// `delete-flashcard.md`). The Leaf list is a stream, so it reflects the
/// change without an explicit invalidate; the store keeps each op atomic.
///
/// Kept alive because the caller only `read`s it (no widget watches its
/// state) — autoDispose would otherwise tear it down mid-command and the
/// pending `state=` would throw.
///
/// Each command also *returns* what it assigned to [state]. Nothing watches
/// this notifier, so a caller that only awaited the future had no way to tell
/// a completed command from a failed one, and hide/delete failures reached
/// nobody (`int-35`). The state assignment stays: the return is the same
/// value, for the caller that is standing right there.
@Riverpod(keepAlive: true)
class CardLifecycleCommandViewmodel extends _$CardLifecycleCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<AsyncValue<void>> setCardHidden({
    required String cardId,
    required bool hidden,
  }) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref
          .read(hideFlashcardUseCaseProvider)
          .setHidden(cardId, hidden: hidden);
    });
    state = result;
    return result;
  }

  Future<AsyncValue<void>> deleteCard({required String cardId}) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref.read(deleteFlashcardUseCaseProvider).deleteCard(cardId);
    });
    state = result;
    return result;
  }

  /// Moves the card, pausing on a duplicate in the target deck.
  ///
  /// `move-flashcard.md` §5 makes a duplicate a decision, not a failure: the
  /// candidates go to [MoveCardDuplicatesViewmodel] and nothing is committed
  /// until an [allowDuplicate] retry. The action state still settles to data —
  /// the picker has to become usable again — so the *commit* is announced by
  /// [MoveCardMovedTickViewmodel] instead. Reporting success off the action
  /// state alone would close the sheet saying "Card moved" over a card that
  /// had not moved.
  Future<AsyncValue<void>> moveCard({
    required String cardId,
    required String targetDeckId,
    bool allowDuplicate = false,
  }) async {
    state = const AsyncLoading<void>();
    MoveFlashcardResult? outcome;
    final result = await runMxAction(() async {
      outcome = await ref
          .read(moveFlashcardUseCaseProvider)
          .call(
            cardId: cardId,
            targetDeckId: targetDeckId,
            allowDuplicate: allowDuplicate,
          );
    });
    final pending = outcome;
    if (pending is MoveDuplicatesFound) {
      ref
          .read(moveCardDuplicatesViewmodelProvider.notifier)
          .show(pending.candidates);
    }
    if (pending is FlashcardMoved) {
      ref.read(moveCardDuplicatesViewmodelProvider.notifier).clear();
      ref.read(moveCardMovedTickViewmodelProvider.notifier).bump();
    }
    state = result;
    return result;
  }
}

/// Cards already in the target deck carrying this term, awaiting the learner's
/// keep-both decision; null when no review is pending (`move-flashcard.md` §5).
// Auto-disposed on purpose: the sheet is the only watcher, so a review that
// was left pending dies with it and the next open starts clean.
@riverpod
class MoveCardDuplicatesViewmodel extends _$MoveCardDuplicatesViewmodel {
  @override
  List<Flashcard>? build() => null;

  void show(List<Flashcard> candidates) => state = candidates;

  void clear() => state = null;
}

/// Increments once per committed move, so the sheet can tell a real move from
/// a duplicate pause — both of which settle the action state to data.
@riverpod
class MoveCardMovedTickViewmodel extends _$MoveCardMovedTickViewmodel {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
