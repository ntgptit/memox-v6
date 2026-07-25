import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';

/// Composes the Today entry projection (WBS 5.7.1; `load-today-dashboard.md`).
///
/// Read-only: it pulls each input from its owning source and never recomputes a
/// business value — the resumable session from [StudySessionRepository], the
/// library card count from [DeckRepository] (for the empty-vs-caught-up split)
/// and the due count from [LearningProgressRepository]. It then picks the single
/// primary action (§2): a paused session wins; else an empty library asks to
/// create; else due cards start a review; else the learner is caught up.
class LoadTodayProjectionUseCase {
  const LoadTodayProjectionUseCase({
    required StudySessionRepository sessions,
    required LearningProgressRepository progress,
    required DeckRepository decks,
    required SelectLanguagePairUseCase languagePairs,
    required AppClock clock,
  }) : _sessions = sessions,
       _progress = progress,
       _decks = decks,
       _languagePairs = languagePairs,
       _clock = clock;

  final StudySessionRepository _sessions;
  final LearningProgressRepository _progress;
  final DeckRepository _decks;
  final SelectLanguagePairUseCase _languagePairs;
  final AppClock _clock;

  Future<TodayProjection> call() async {
    final paused = await _sessions.watchActive().first;
    final pair = await _languagePairs.activePair();
    final libraryCardCount = pair == null
        ? 0
        : await _decks.countForLanguagePair(pair.id);
    final dueCount = await _progress.countDue(_clock.nowUtc());

    final action = paused != null
        ? TodayPrimaryAction.continueSession
        : libraryCardCount == 0
        ? TodayPrimaryAction.createLibrary
        : dueCount > 0
        ? TodayPrimaryAction.startReview
        : TodayPrimaryAction.caughtUp;

    return TodayProjection(
      primaryAction: action,
      dueCount: dueCount,
      pausedSession: paused,
    );
  }
}
