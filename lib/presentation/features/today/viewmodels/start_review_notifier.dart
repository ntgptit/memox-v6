import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/today/start_review_outcome.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'start_review_notifier.g.dart';

/// The `Start review` command (WBS 5.7.3; `start-review-from-today.md`).
///
/// Holds the resolved [StartReviewOutcome] rather than `void`, because the
/// four branches of §2 need different handling and a bare success would leave
/// the screen guessing which one happened.
///
/// §4: "Starting khóa CTA/double tap" — the re-entrancy guard is here, not in
/// the button, so a second tap cannot start a second request no matter which
/// control dispatched it.
@riverpod
class StartReview extends _$StartReview {
  @override
  AsyncValue<StartReviewOutcome?> build() =>
      const AsyncData<StartReviewOutcome?>(null);

  Future<void> start({
    SessionType type = SessionType.dueReview,
    String? deckId,
  }) async {
    if (state is AsyncLoading<StartReviewOutcome?>) return;
    state = const AsyncLoading<StartReviewOutcome?>();

    StartReviewOutcome? outcome;
    final result = await runMxAction(() async {
      outcome = await ref
          .read(startReviewFromTodayUseCaseProvider)
          .call(type: type, deckId: deckId);
    });

    // §4: "Start failure giữ Dashboard snapshot" — a failed start leaves the
    // dashboard exactly as it was and reports, rather than navigating anyone
    // anywhere.
    state = switch (result) {
      AsyncError<void>(:final error, :final stackTrace) =>
        AsyncError<StartReviewOutcome?>(error, stackTrace),
      _ => AsyncData<StartReviewOutcome?>(outcome),
    };
  }
}
