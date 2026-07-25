import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'match_flush_notifier.g.dart';

/// Commits a completed Match board to the session (WBS 5.6.6).
///
/// The board resolves pairs in free order, but the session runtime is a
/// sequential cursor, so the round is committed at completion: this threads
/// [AnswerStudyStageUseCase] over the per-card [MatchInput]s in cursor order —
/// each call returns the advanced runtime, so the cursor walks `0..N-1` without
/// an async re-read between writes — then invalidates the runtime once so the
/// screen re-reads the next mastery round or stage. A save failure surfaces as a
/// typed [AsyncError]; the board is untouched so the learner can retry.
@riverpod
class MatchFlush extends _$MatchFlush {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> flush(List<MatchInput> inputs) async {
    if (state is AsyncLoading<void>) return;
    final current = ref.read(studySessionRuntimeProvider).asData?.value;
    if (current == null || inputs.isEmpty) return;

    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      final useCase = ref.read(answerStudyStageUseCaseProvider);
      var runtime = current;
      for (final input in inputs) {
        runtime = await useCase.call(runtime, input);
      }
      ref.invalidate(studySessionRuntimeProvider);
    });
  }
}
