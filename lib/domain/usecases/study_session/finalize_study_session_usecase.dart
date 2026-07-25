import 'dart:convert';

import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_session/session_mode_plan.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/domain/study_session/session_terminal_grade_policy.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/study_streak/record_streak_day_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/track_daily_goal_usecase.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';
import 'package:memox_v6/domain/study_streak/streak_projection_policy.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';
import 'package:memox_v6/domain/study_goal/daily_goal_contribution.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';

/// Closes a completed study session (WBS 5.6.13; `finalize-study-session.md`).
///
/// It reads the session's committed attempts, aggregates one terminal SRS grade
/// per card ([SessionTerminalGradePolicy]), and — when the session schedules SRS
/// — applies each SRS-active card's terminal outcome exactly once through
/// [ApplyTerminalOutcomeUseCase] (a Box 0 card that finished the pipeline
/// activates to Box 1 per SRS8-001; an already-activated card applies its binary
/// grade per SRS8-003–024). It then commits the completion via
/// [StudySessionRepository.finalizeSession] and returns the committed
/// [StudySessionSummary].
///
/// Idempotent by construction: each card's synthesized terminal attempt carries
/// the stable `terminal:<sessionId>:<cardId>` idempotency key (the spec's
/// `terminalOutcomeId`, `srs-8-box-policy.md` §7), so a finalize retry re-applies
/// nothing (SRS8-011). Practice sessions (`scheduleSrs == false`) schedule no SRS
/// but still finalize (SRS8-027). Goal/streak contributions are deferred and
/// passed as `null`.
class FinalizeStudySessionUseCase {
  const FinalizeStudySessionUseCase({
    required StudySessionRepository sessions,
    required LearningProgressRepository progress,
    required ApplyTerminalOutcomeUseCase applyTerminalOutcome,
    required AppClock clock,
    required IdGenerator idGenerator,
    RecordStreakDayUseCase? recordStreakDay,
    TrackDailyGoalUseCase? trackDailyGoal,
    StreakRepository? streaks,
    AppTimeZone? timeZone,
    StreakProjectionPolicy streakPolicy = const StreakProjectionPolicy(),
    SessionModePlanResolver planResolver = const SessionModePlanResolver(),
    SessionTerminalGradePolicy gradePolicy = const SessionTerminalGradePolicy(),
    SessionSummaryPolicy summaryPolicy = const SessionSummaryPolicy(),
  }) : _sessions = sessions,
       _progress = progress,
       _applyTerminalOutcome = applyTerminalOutcome,
       _clock = clock,
       _idGenerator = idGenerator,
       _recordStreakDay = recordStreakDay,
       _trackDailyGoal = trackDailyGoal,
       _streaks = streaks,
       _timeZone = timeZone,
       _streakPolicy = streakPolicy,
       _planResolver = planResolver,
       _gradePolicy = gradePolicy,
       _summaryPolicy = summaryPolicy;

  final StudySessionRepository _sessions;
  final LearningProgressRepository _progress;
  final ApplyTerminalOutcomeUseCase _applyTerminalOutcome;
  final AppClock _clock;
  final IdGenerator _idGenerator;

  /// Optional so the many existing constructions of this use case keep
  /// working; when absent the streak simply is not offered the session.
  final RecordStreakDayUseCase? _recordStreakDay;

  /// Same contract as [_recordStreakDay]: optional, and never able to fail the
  /// session it is reporting on.
  final TrackDailyGoalUseCase? _trackDailyGoal;

  /// Read back so the result can report the streak the session just extended.
  /// Optional alongside the two writers: a caller that supplies neither gets a
  /// summary with no goal status, exactly as before.
  final StreakRepository? _streaks;
  final AppTimeZone? _timeZone;
  final StreakProjectionPolicy _streakPolicy;
  final SessionModePlanResolver _planResolver;
  final SessionTerminalGradePolicy _gradePolicy;
  final SessionSummaryPolicy _summaryPolicy;

  Future<StudySessionSummary> call(StudyRuntimeState runtime) async {
    if (!runtime.isComplete) {
      throw ValidationFailure(field: 'session', code: 'not-complete');
    }
    final session = runtime.session;
    final now = _clock.nowUtc();

    final attempts = await _sessions.attempts(session.id);
    final outcomes = <CardOutcome>[
      for (final attempt in attempts)
        if (ModeOutcome.tryFromId(attempt.outcome) case final outcome?)
          (cardId: attempt.cardId, outcome: outcome),
    ];

    final summary = _summaryPolicy.summarize(outcomes);

    // Schedule SRS exactly once per card, unless this is a practice session.
    if (session.scheduleSrs) {
      final grades = _gradePolicy.gradesByCard(outcomes);
      // The aggregate terminal attempt's provenance mode is the session's plan.
      final planId = _planResolver.resolve(type: session.type).planId;
      for (final entry in grades.entries) {
        await _scheduleCard(session.id, entry.key, entry.value, planId, now);
      }
    }

    await _sessions.finalizeSession(
      sessionId: session.id,
      expectedRevision: session.revision,
      terminalState: SessionState.completed,
      finalizedAt: now,
    );

    // Offered only after the session is committed, and never allowed to undo
    // it: `record-streak-day.md` §1 — "Ghi streak không được rollback Study
    // Session đã thành công". A storage failure here loses a streak day, which
    // reconciliation can rebuild from session history (§4); letting it
    // propagate would instead lose the finished session, which nothing can.
    final recordStreakDay = _recordStreakDay;
    if (recordStreakDay != null) {
      try {
        await recordStreakDay(
          sessionId: session.id,
          sessionType: session.type,
          qualifiedCardCount: summary.reviewedCount,
          finalizedAt: now,
        );
      } on Object {
        // Swallowed deliberately, and narrowly: the session is already
        // durable, and the caller asked to finalize a session, not to record a
        // streak.
      }
    }

    // Its own try rather than sharing the streak's: the two projections are
    // independent, and a streak-store failure must not also cost the day's
    // goal progress.
    var contribution = const DailyGoalContribution.inactive();
    final trackDailyGoal = _trackDailyGoal;
    if (trackDailyGoal != null) {
      try {
        contribution = await trackDailyGoal(
          qualifiedCardCount: summary.reviewedCount,
          finalizedAt: now,
        );
      } on Object {
        // As above: a projection is rebuildable from session history, a
        // finalized session is not.
      }
    }

    return summary.withGoalStatus(await _goalStatus(contribution, now));
  }

  /// The streak + goal card's content, read back from what was just written.
  ///
  /// Null unless there is an active goal to report against: the card shows
  /// today's target, so with no goal configured there is nothing to show. The
  /// streak is derived rather than counted incrementally, because
  /// `calculate-current-streak.md` makes the projection a read over the day
  /// records — nothing stores a running total to drift.
  Future<StudyResultGoalStatus?> _goalStatus(
    DailyGoalContribution contribution,
    DateTime now,
  ) async {
    if (!contribution.isActive) return null;

    final streaks = _streaks;
    final timeZone = _timeZone;
    if (streaks == null || timeZone == null) return null;

    try {
      final today = timeZone.localDayOf(now);
      // The whole history: `longest` needs it, and a current run has no bound
      // this could safely assume.
      final days = await streaks.daysBetween('0000-01-01', today.toString());
      final projection = _streakPolicy.project(
        days: days.map(_localDayOf).whereType<LocalDay>(),
        effectiveDay: today,
      );
      return StudyResultGoalStatus(
        streakDays: projection.current,
        goalDoneCards: contribution.currentAmount,
        goalTargetCards: contribution.target,
      );
    } on Object {
      // Same rule as the writes: a summary without its streak card is a worse
      // result screen, not a failed session.
      return null;
    }
  }

  /// Stored days carry their date as `YYYY-MM-DD` text; a row that cannot be
  /// parsed is skipped rather than crashing the result, and
  /// `reconcile-streak-history.md` owns repairing it.
  LocalDay? _localDayOf(StreakDay day) {
    final parts = day.localDate.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final dayOfMonth = int.tryParse(parts[2]);
    if (year == null || month == null || dayOfMonth == null) return null;
    return LocalDay(year, month, dayOfMonth);
  }

  Future<void> _scheduleCard(
    String sessionId,
    String cardId,
    SrsGrade grade,
    String planId,
    DateTime now,
  ) async {
    // Branch on the card's CURRENT box (not the start snapshot) so a finalize
    // retry after a partial run is safe: a card already activated by the first
    // run reads Box 1..8 and takes the applyGrade path, where the terminal
    // idempotency key makes the write a no-op instead of throwing.
    final current = await _progress.findByCard(cardId);
    if (current == null) return; // deleted card — no progress to schedule.

    final attempt = StudyAttempt(
      id: _idGenerator.newId(),
      // Stable per session+card so a finalize retry is a no-op (SRS8-011).
      idempotencyKey: 'terminal:$sessionId:$cardId',
      cardId: cardId,
      sessionId: sessionId,
      modeId: planId,
      outcome: grade == SrsGrade.correct
          ? ModeOutcome.correct.id
          : ModeOutcome.wrong.id,
      evidenceJson: jsonEncode(<String, Object?>{
        'terminalGrade': grade.name,
        'source': 'finalize',
      }),
      isTerminal: true,
      createdAt: now,
    );

    // A new card that finished the pipeline activates (SRS8-001); an already
    // activated card applies its binary terminal grade (SRS8-003–024).
    if (current.box == Srs8BoxPolicy.newBox) {
      await _applyTerminalOutcome.activate(attempt: attempt, nowUtc: now);
      return;
    }
    await _applyTerminalOutcome.applyGrade(
      attempt: attempt,
      grade: grade,
      nowUtc: now,
    );
  }
}
