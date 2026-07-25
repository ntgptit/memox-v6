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
    SessionModePlanResolver planResolver = const SessionModePlanResolver(),
    SessionTerminalGradePolicy gradePolicy = const SessionTerminalGradePolicy(),
    SessionSummaryPolicy summaryPolicy = const SessionSummaryPolicy(),
  }) : _sessions = sessions,
       _progress = progress,
       _applyTerminalOutcome = applyTerminalOutcome,
       _clock = clock,
       _idGenerator = idGenerator,
       _planResolver = planResolver,
       _gradePolicy = gradePolicy,
       _summaryPolicy = summaryPolicy;

  final StudySessionRepository _sessions;
  final LearningProgressRepository _progress;
  final ApplyTerminalOutcomeUseCase _applyTerminalOutcome;
  final AppClock _clock;
  final IdGenerator _idGenerator;
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

    return summary;
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
