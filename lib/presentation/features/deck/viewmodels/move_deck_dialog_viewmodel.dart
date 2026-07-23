import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'move_deck_dialog_viewmodel.g.dart';

/// Submit command of the move-deck flow (WBS 6.1; `move-deck.md`, kit
/// `deck-settings--move`).
///
/// Runs [MoveDeckUseCase] behind [runMxAction]; the store owns the structural
/// invariants (cycle / mixed-content / pair / duplicate), so an ineligible move
/// surfaces as a typed [AsyncError] the caller shows. [newParentId] `null` moves
/// the deck to the Library root.
@riverpod
class MoveDeckDialogViewmodel extends _$MoveDeckDialogViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> moveDeck({
    required String deckId,
    required String? newParentId,
  }) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref
          .read(moveDeckUseCaseProvider)
          .call(deckId: deckId, newParentId: newParentId);
    });
  }
}
