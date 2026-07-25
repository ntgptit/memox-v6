import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_start_notifier.g.dart';

/// Command notifier that starts a study session for a deck scope (WBS 5.6.1/2;
/// `start-study-session.md`). It runs [StartStudySessionUseCase] behind
/// [runMxAction], so start eligibility failures (no eligible cards, a due queue
/// that is caught up) and a conflicting active session surface as a typed
/// [AsyncError] the caller shows; on success the caller navigates to `/study`,
/// where the dispatcher resumes the freshly committed session into its first
/// stage. The screen never touches a repository.
@riverpod
class StudyStart extends _$StudyStart {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> start({
    required String deckId,
    SessionType type = SessionType.newLearning,
  }) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref
          .read(startStudySessionUseCaseProvider)
          .call(deckId: deckId, scope: SessionScope.subtree, type: type);
    });
  }
}
