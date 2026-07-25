import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rename_deck_dialog_viewmodel.g.dart';

/// Submit command of the rename-deck dialog (WBS 6.1; `edit-deck.md`, kit
/// `deck-settings--rename`).
///
/// Runs [RenameDeckUseCase] behind [runMxAction], so a validation error
/// (empty / too-long name) or a sibling-name [ConflictFailure] surfaces as a
/// typed [AsyncError] the form shows; the dialog closes on success. The command
/// never touches a repository directly.
@riverpod
class RenameDeckDialogViewmodel extends _$RenameDeckDialogViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> rename({required String deckId, required String name}) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref
          .read(renameDeckUseCaseProvider)
          .call(deckId: deckId, name: name);
    });
  }
}
