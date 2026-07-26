import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_answer_viewmodel.g.dart';

/// Command notifier for submitting a stage answer (WBS 5.6.3;
/// `answer-study-stage.md`). It persists the attempt + advanced checkpoint via
/// the use case, then invalidates the runtime query so the screen re-reads the
/// committed position. A save failure surfaces as a typed [AsyncError] and the
/// runtime is left untouched (the caller keeps the answer for Retry).
@riverpod
class StudyAnswerViewmodel extends _$StudyAnswerViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// The answer awaiting a successful save, for [retry].
  ///
  /// §6's failure dialog offers `Try again`, and the attempt carries its own
  /// request id, so re-submitting the same input is the same attempt rather
  /// than a second one ("Retry cùng attempt không tạo record hoặc progress
  /// update lần hai").
  StudyModeInput? _pending;

  Future<void> answer(StudyModeInput input) async {
    if (state is AsyncLoading<void>) return;
    final current = ref.read(studySessionRuntimeProvider).asData?.value;
    if (current == null) return;

    _pending = input;
    state = const AsyncLoading();
    final result = await runMxAction(() async {
      await ref.read(answerStudyStageUseCaseProvider).call(current, input);
      ref.invalidate(studySessionRuntimeProvider);
    });
    if (result is AsyncData<void>) _pending = null;
    state = result;
  }

  /// Re-submits the answer a failed save is still holding (§6 `Try again`).
  Future<void> retry() async {
    final pending = _pending;
    if (pending == null) return;
    state = const AsyncData<void>(null);
    return answer(pending);
  }
}
