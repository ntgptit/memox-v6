import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_deck_dialog_viewmodel.g.dart';

/// Submit command of the delete-deck confirm dialog (WBS 6.1; `delete-deck.md`,
/// kit `deck-settings--delete-confirm`).
///
/// Runs [DeleteDeckUseCase] behind [runMxAction] — the atomic subtree cascade is
/// irreversible, so the dialog confirms first. A store failure surfaces as a
/// typed [AsyncError] the dialog shows ("Nothing removed · Retry"); on success
/// the caller navigates to the surviving context (the deck is gone).
@riverpod
class DeleteDeckDialogViewmodel extends _$DeleteDeckDialogViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> deleteDeck(String deckId) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref.read(deleteDeckUseCaseProvider).call(deckId);
    });
  }
}
