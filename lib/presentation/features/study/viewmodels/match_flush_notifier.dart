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

  /// The board this flush is still trying to commit, for [retry].
  List<MatchInput> _pending = const <MatchInput>[];

  Future<void> flush(List<MatchInput> inputs) async {
    if (state is AsyncLoading<void>) return;
    // Awaited rather than read from the cache: a retry follows a flush that
    // committed part of the board, and the cached runtime is the one from
    // before those writes. Starting from it would re-answer the prefix.
    final current = await ref.read(studySessionRuntimeProvider.future);
    if (current == null || inputs.isEmpty) return;

    _pending = inputs;
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      final useCase = ref.read(answerStudyStageUseCaseProvider);
      var runtime = current;
      for (final input in inputs) {
        // A retry re-sends the whole board, and part of it may already be
        // committed: the loop writes card by card, so a failure halfway
        // leaves a committed prefix behind. An input for a card the cursor
        // has passed is that prefix, and re-answering it would write a
        // second attempt for a card that already has one — at a different
        // position, so the idempotency key would not catch it.
        if (runtime.position.currentCardId != input.cardId) continue;
        runtime = await useCase.call(runtime, input);
      }
    });
    // Invalidated whatever happened: a failure halfway still moved the store,
    // so the runtime the screen and the retry read has to be re-read from it.
    ref.invalidate(studySessionRuntimeProvider);
    if (result is AsyncData<void>) _pending = const <MatchInput>[];
    state = result;
  }

  /// Re-commits the board a failed flush is still holding.
  Future<void> retry() async {
    final pending = _pending;
    if (pending.isEmpty) return;
    state = const AsyncData<void>(null);
    return flush(pending);
  }
}
