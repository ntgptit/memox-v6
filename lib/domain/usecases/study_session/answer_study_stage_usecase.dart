import 'dart:convert';

import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/round_order_policy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// Commits one stage answer and advances the runtime (WBS 5.6.3;
/// `answer-study-stage.md`).
///
/// It maps the interaction to canonical evidence via the mode strategy, writes
/// an intermediate attempt and the advanced checkpoint (plus a freshly generated
/// round order when a new round/stage opens) in one atomic op, then returns the
/// next [StudyRuntimeState]. Attempts are non-terminal here — the terminal SRS
/// grade is aggregated at finalize (5.6.13). The attempt's idempotency key is
/// derived from the position + event, so a save retry never double-writes.
class AnswerStudyStageUseCase {
  const AnswerStudyStageUseCase({
    required StudySessionRepository sessions,
    required StudyModeFactory factory,
    required AppClock clock,
    required IdGenerator idGenerator,
    SessionAdvancePolicy advancePolicy = const SessionAdvancePolicy(),
  }) : _sessions = sessions,
       _factory = factory,
       _clock = clock,
       _idGenerator = idGenerator,
       _advancePolicy = advancePolicy;

  final StudySessionRepository _sessions;
  final StudyModeFactory _factory;
  final AppClock _clock;
  final IdGenerator _idGenerator;
  final SessionAdvancePolicy _advancePolicy;

  Future<StudyRuntimeState> call(
    StudyRuntimeState current,
    StudyModeInput input,
  ) async {
    final mode = current.currentMode;
    final cardId = current.position.currentCardId;
    if (cardId == null) return current; // already complete — nothing to answer

    final evidence = _factory.create(mode).evaluate(input);
    final passed =
        evidence.outcome == ModeOutcome.correct ||
        evidence.outcome == ModeOutcome.reviewed;
    final now = _clock.nowUtc();
    final sessionId = current.session.id;

    final position = current.position;
    // Deterministic per (position, event): a save retry reuses the same key.
    final idempotencyKey =
        '$sessionId:${position.stageIndex}:${position.roundIndex}:'
        '${position.cardPosition}:${evidence.eventId}';
    final attempt = StudyAttempt(
      id: _idGenerator.newId(),
      idempotencyKey: idempotencyKey,
      cardId: cardId,
      sessionId: sessionId,
      modeId: mode.id,
      outcome: evidence.outcome.id,
      evidenceJson: jsonEncode(<String, Object?>{
        'mode': evidence.mode.id,
        'outcome': evidence.outcome.id,
        'reason': evidence.reason?.id,
        'eventId': evidence.eventId,
        'roundIndex': evidence.roundIndex,
        'mappingVersion': evidence.mappingVersion,
      }),
      isTerminal: false,
      createdAt: now,
    );

    final next = _advancePolicy.next(
      sessionId: sessionId,
      stages: current.stages,
      allSessionCardIds: current.allCardIdsInBaseOrder,
      current: position,
      currentCardPassed: passed,
    );

    final checkpoint = SessionCheckpoint(
      id: 'cp-$sessionId',
      sessionId: sessionId,
      stageIndex: next.stageIndex,
      roundIndex: next.roundIndex,
      cardPosition: next.cardPosition,
      failedCardIds: next.failedCardIds,
      timerStateJson: '{}',
      stateVersion: position.roundIndex + position.cardPosition + 1,
      updatedAt: now,
    );

    // A new round or stage generated a new order; persist it atomically.
    final newOrder = next.roundIndex != position.roundIndex
        ? SessionRoundOrder(
            id: 'ro-$sessionId-${next.roundIndex}',
            sessionId: sessionId,
            roundIndex: next.roundIndex,
            seed: roundOrderSeed(
              sessionId: sessionId,
              modeId: current.stages[next.stageIndex].id,
              roundIndex: next.roundIndex,
            ),
            cardIds: next.roundCardIds,
          )
        : null;

    await _sessions.saveAttemptWithCheckpoint(
      attempt: attempt,
      checkpoint: checkpoint,
      newRoundOrder: newOrder,
    );

    return StudyRuntimeState(
      session: current.session,
      stages: current.stages,
      position: next,
      cardsById: current.cardsById,
    );
  }
}
