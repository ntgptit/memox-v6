import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_deck_progress_dialog_viewmodel.g.dart';

/// Submit command of the reset-progress confirm dialog (WBS 6.1;
/// `reset-deck-progress.md`).
///
/// Runs [ResetDeckProgressUseCase] behind [runMxAction] — the subtree reset is
/// irreversible, so the dialog confirms first. A store failure surfaces as a
/// typed [AsyncError] the dialog shows ("No partial reset · Retry"); on success
/// the caller refreshes the deck (progress changed, the deck stays).
@riverpod
class ResetDeckProgressDialogViewmodel
    extends _$ResetDeckProgressDialogViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> resetDeckProgress(String deckId) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref.read(resetDeckProgressUseCaseProvider).call(deckId);
    });
  }
}
