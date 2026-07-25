import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_result_notifier.g.dart';

/// The finalize + result state for a completed study session (WBS 5.6.13;
/// `finalize-study-session.md`). It runs [FinalizeStudySessionUseCase] exactly
/// once and holds the committed [StudySessionSummary] so the result survives the
/// active session being cleared by finalize (a Notifier's state persists, unlike
/// a runtime-derived provider that would re-emit null once the session closes).
///
/// States map to the kit `study-result` shots: `AsyncData(null)` = not yet
/// finalized, `AsyncLoading` = finalizing, `AsyncError` = finalize-error (Retry),
/// `AsyncData(summary)` = the result.
@riverpod
class StudyResult extends _$StudyResult {
  @override
  AsyncValue<StudySessionSummary?> build() =>
      const AsyncData<StudySessionSummary?>(null);

  /// Finalizes the completed session once. A no-op unless the state is the
  /// initial not-yet-finalized value, so the trigger can fire on every rebuild
  /// without re-committing (the use case is itself idempotent as a second guard).
  Future<void> finalize() async {
    final current = state;
    if (current is! AsyncData<StudySessionSummary?> || current.value != null) {
      return;
    }
    final runtime = ref.read(studySessionRuntimeProvider).asData?.value;
    if (runtime == null || !runtime.isComplete) return;

    state = const AsyncLoading<StudySessionSummary?>();
    StudySessionSummary? summary;
    final action = await runMxAction(() async {
      summary = await ref
          .read(finalizeStudySessionUseCaseProvider)
          .call(runtime);
    });
    state = switch (action) {
      AsyncError(:final error, :final stackTrace) =>
        AsyncError<StudySessionSummary?>(error, stackTrace),
      _ => AsyncData<StudySessionSummary?>(summary),
    };
  }

  /// Re-attempts a failed finalize (`finalize-study-session.md` §6).
  Future<void> retry() {
    state = const AsyncData<StudySessionSummary?>(null);
    return finalize();
  }
}
