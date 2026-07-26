import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';

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
  /// The source session's scope, captured while finalizing.
  ///
  /// Relearn starts from this screen after the active session is gone, and a
  /// session row needs a deck. The runtime that knows it is cleared by
  /// finalize, so it is remembered here rather than re-derived from a session
  /// that no longer exists.
  String? _sourceDeckId;
  SessionScope? _sourceScope;

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

    _sourceDeckId = runtime.session.deckId;
    _sourceScope = runtime.session.scope;

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

  /// Starts a relearn session over the cards this session got wrong
  /// (`relearn-cards.md` §1: "Relearn là session mới do user explicit start
  /// từ `Review missed`").
  ///
  /// Returns the start's outcome, or null when there was nothing to start —
  /// so the caller navigates on success, reports a failure, and stays quiet
  /// about a tap that was never going to do anything. `Review mistakes` used
  /// to call `goStudy()` and nothing else — it re-entered the route the result
  /// was already on, so the missed cards were never relearned and the control
  /// did nothing at all.
  Future<AsyncValue<void>?> startRelearn() async {
    final summary = state.asData?.value;
    final deckId = _sourceDeckId;
    final scope = _sourceScope;
    if (summary == null || deckId == null || scope == null) return null;
    if (summary.missedCardIds.isEmpty) return null;
    // A second tap while the first start is still in flight would find the
    // session it is about to create and fail on the one-active-session rule —
    // reporting a conflict for what is really one request.
    if (_starting) return null;

    _starting = true;
    final action = await runMxAction(() async {
      await ref
          .read(startStudySessionUseCaseProvider)
          .call(
            deckId: deckId,
            scope: scope,
            type: SessionType.relearn,
            relearnCardIds: summary.missedCardIds,
          );
    });
    _starting = false;
    return action;
  }

  /// Whether a relearn start is in flight; see [startRelearn].
  bool _starting = false;
}
