import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_goal/daily_progress_status.dart';

/// The single primary call-to-action the Today entry surfaces
/// (`load-today-dashboard.md` §2). Exactly one is chosen from the composed
/// projections; the order below is the priority (a resumable session wins).
enum TodayPrimaryAction {
  /// A paused/resumable session exists — Continue learning.
  continueSession,

  /// The library has cards but none are due yet, and no session — Caught up.
  caughtUp,

  /// Cards are due — Start review.
  startReview,

  /// The active pair has no cards — Create/import guidance.
  createLibrary,
}

/// A read-only composition of the Today entry state
/// (WBS 5.7.1; `load-today-dashboard.md`). It **owns no source calculations** —
/// each field is pulled from its owning source (the active session, the due
/// count, the library card count) and never recomputed here.
///
/// New-card and relearn counts are not yet composed: there is no library-wide
/// new-count query (`studyCandidatesInScope` is per-deck) and the relearn queue
/// is session-derived with relearn-session start deferred (GAP-A). They are
/// added once their sources exist.
class TodayProjection {
  const TodayProjection({
    required this.primaryAction,
    required this.dueCount,
    this.newCount = 0,
    this.pausedSession,
    this.dailyProgress = const DailyProgressStatus.none(),
    this.recentDecks = const <DeckSummary>[],
    this.libraryMastery = const LibraryMastery.empty(),
  });

  /// How many deck rows Today shows (kit `dashboard/decks`: three, then a
  /// "See all decks" link to the Library rather than a longer list).
  static const int recentDeckLimit = 3;

  final TodayPrimaryAction primaryAction;

  /// Cards due for review in the **active pair** (from
  /// `LoadStudyQueueCountsUseCase.forLibrary`).
  ///
  /// Pair-scoped like the rest of this projection. It read an unscoped count
  /// once, which advertised review work from decks the Library does not show.
  final int dueCount;

  /// Cards never studied in the **active pair**, from the same read as
  /// [dueCount].
  ///
  /// What the caught-up state's optional action needs
  /// (`handle-caught-up-today.md` §2 node G): a learner with nothing due may
  /// still have a library of cards they have not started, and until this was
  /// composed Today could not say so.
  final int newCount;

  /// The resumable active session, or `null` when none is in progress.
  final StudySession? pausedSession;

  /// Today's streak and goal standing, for the kit's Daily-goal card. Always
  /// present; `hasGoal` is false when none is configured, which is the card's
  /// own not-shown condition rather than a missing value.
  final DailyProgressStatus dailyProgress;

  /// The most recently studied root decks of the active pair, newest first —
  /// the kit's Recent-decks section. A supporting section by
  /// `load-today-dashboard.md` §3, so it is empty rather than fatal when the
  /// library has nothing in it.
  final List<DeckSummary> recentDecks;

  /// The mastered share of the active pair's library — the stat strip's
  /// "library mastered". Zero when there is no pair, which is also what an
  /// empty library reads.
  final LibraryMastery libraryMastery;
}
