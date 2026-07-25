import 'package:memox_v6/domain/study_session/study_session.dart';

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
    this.pausedSession,
  });

  final TodayPrimaryAction primaryAction;

  /// Library-wide count of cards due for review (from `countDue`).
  final int dueCount;

  /// The resumable active session, or `null` when none is in progress.
  final StudySession? pausedSession;
}
