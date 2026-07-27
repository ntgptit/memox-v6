import 'package:memox_v6/presentation/features/deck/viewmodels/deck_deletion_impact_provider.dart';
import 'package:memox_v6/domain/deck/reset_progress_result.dart';
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

  /// Submits the reset for the scope the confirm showed.
  ///
  /// §5 refreshes the counts before submit and §11 makes a changed impact its
  /// own row: the learner confirms again rather than having a different scope
  /// reset under the number they agreed to. A change is a decision, not a
  /// failure, so it goes to [ResetImpactChangedViewmodel] and the action state
  /// settles to data — the dialog must become usable again either way.
  Future<void> resetDeckProgress(
    String deckId, {
    required int expectedAffectedCount,
  }) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading<void>();
    ResetProgressResult? outcome;
    final result = await runMxAction(() async {
      outcome = await ref
          .read(resetDeckProgressUseCaseProvider)
          .call(deckId, expectedAffectedCount: expectedAffectedCount);
    });
    final settled = outcome;
    if (settled is ResetImpactChanged) {
      ref.read(resetImpactChangedViewmodelProvider.notifier).show();
      // The dialog reads its impact from a cached future; the number it shows
      // has to become the number the store just reported.
      ref.invalidate(deckDeletionImpactProvider(deckId: deckId));
    }
    if (settled is ProgressReset) {
      ref.read(resetImpactChangedViewmodelProvider.notifier).clear();
      ref.read(resetAppliedTickViewmodelProvider.notifier).bump();
    }
    state = result;
  }
}

/// Whether the affected count moved between the confirm and the submit, so the
/// dialog can ask again (§5, §11). Auto-disposed: the dialog is the only
/// watcher, so a pending re-confirm dies with it.
@riverpod
class ResetImpactChangedViewmodel extends _$ResetImpactChangedViewmodel {
  @override
  bool build() => false;

  void show() => state = true;

  void clear() => state = false;
}

/// Increments once per applied reset, so the dialog can tell a real reset from
/// a re-confirm — both of which settle the action state to data.
@riverpod
class ResetAppliedTickViewmodel extends _$ResetAppliedTickViewmodel {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
