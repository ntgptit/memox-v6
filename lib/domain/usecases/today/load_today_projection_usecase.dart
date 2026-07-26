import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/load_daily_progress_usecase.dart';
import 'package:memox_v6/domain/study_goal/daily_progress_status.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/domain/learning_progress/study_queue_counts.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';

/// Composes the Today entry projection (WBS 5.7.1; `load-today-dashboard.md`).
///
/// Read-only: it pulls each input from its owning source and never recomputes a
/// business value — the resumable session from [StudySessionRepository], the
/// library card count from [DeckRepository] (for the empty-vs-caught-up split)
/// and the due count from [LoadStudyQueueCountsUseCase], scoped to the active pair. It then picks the single
/// primary action (§2): a paused session wins; else an empty library asks to
/// create; else due cards start a review; else the learner is caught up.
class LoadTodayProjectionUseCase {
  const LoadTodayProjectionUseCase({
    required StudySessionRepository sessions,
    required DeckRepository decks,
    required SelectLanguagePairUseCase languagePairs,
    required LoadStudyQueueCountsUseCase queueCounts,
    LoadDailyProgressUseCase? dailyProgress,
  }) : _sessions = sessions,
       _decks = decks,
       _languagePairs = languagePairs,
       _queueCounts = queueCounts,
       _dailyProgress = dailyProgress;

  final StudySessionRepository _sessions;
  final DeckRepository _decks;
  final SelectLanguagePairUseCase _languagePairs;
  final LoadStudyQueueCountsUseCase _queueCounts;

  /// Optional so existing constructions keep working; without it the
  /// projection reports no goal, which is the card's not-shown state.
  final LoadDailyProgressUseCase? _dailyProgress;

  Future<TodayProjection> call() async {
    final paused = await _sessions.watchActive().first;
    final pair = await _languagePairs.activePair();
    final libraryCardCount = pair == null
        ? 0
        : await _decks.countForLanguagePair(pair.id);
    // Scoped to the active pair, like the library count above it.
    //
    // This read `LearningProgressRepository.countDue`, whose SQL has no
    // language-pair filter — it counts every due card in the database. With
    // two pairs configured, Today advertised review work from a pair whose
    // decks the Library does not even show, and the number disagreed with the
    // scope the session would actually run over. `LoadStudyQueueCountsUseCase`
    // has documented itself as "the Dashboard scope" since 5.4.2 and was wired
    // into DI but never called by anything. That unscoped read has since been
    // deleted from the port, so the mistake is not available to repeat.
    final queues = pair == null
        ? const StudyQueueCounts(dueCount: 0, newCount: 0)
        : await _queueCounts.forLibrary(pair.id);
    final dueCount = queues.dueCount;

    final action = paused != null
        ? TodayPrimaryAction.continueSession
        : libraryCardCount == 0
        ? TodayPrimaryAction.createLibrary
        : dueCount > 0
        ? TodayPrimaryAction.startReview
        : TodayPrimaryAction.caughtUp;

    // Two of the three sources the kit's Daily-goal card needs now exist
    // (goal + streak); time-studied does not, because nothing captures
    // foreground-active intervals — see `int-9`.
    final dailyProgress =
        await _dailyProgress?.call() ?? const DailyProgressStatus.none();

    // Read after the primary action is settled: the deck rows are a supporting
    // section (§3), so they are the part that may come back empty without
    // changing what Today asks the learner to do.
    final recentDecks = pair == null
        ? const <DeckSummary>[]
        : await _decks.recentSummaries(
            pair.id,
            limit: TodayProjection.recentDeckLimit,
          );

    // Box 8 is a state rather than a schedule, so this asks for no instant —
    // it is the same library scope as the due count, partitioned by box.
    final mastery = pair == null
        ? const LibraryMastery.empty()
        : await _queueCounts.masteryForLibrary(pair.id);

    return TodayProjection(
      primaryAction: action,
      dueCount: dueCount,
      newCount: queues.newCount,
      pausedSession: paused,
      dailyProgress: dailyProgress,
      recentDecks: recentDecks,
      libraryMastery: mastery,
    );
  }
}
