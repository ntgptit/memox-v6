import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_runtime_provider.g.dart';

/// Query provider for the active study session's runtime (WBS 5.6.3;
/// `resume-study-session.md` §7). It delegates to [LoadStudyRuntimeUseCase] —
/// presentation never touches the repository — projecting the committed
/// snapshot + checkpoint + current round order into a [StudyRuntimeState], or
/// `null` when no session is active. The command viewmodel invalidates this
/// after each answer so the screen re-reads the persisted position.
@riverpod
Future<StudyRuntimeState?> studySessionRuntime(Ref ref) {
  return ref.watch(loadStudyRuntimeUseCaseProvider).call();
}
