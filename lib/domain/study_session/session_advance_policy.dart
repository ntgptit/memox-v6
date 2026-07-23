import 'package:memox_v6/domain/study_modes/round_order_policy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// Whether the session runtime is mid-plan or has finished every stage.
enum SessionPhase { inRound, sessionComplete }

/// An immutable position in a running session: the current stage, mastery round,
/// its committed card order and cursor, plus the failed set accumulating for the
/// current round. Reproduced verbatim from the committed checkpoint on resume.
class SessionPosition {
  const SessionPosition({
    required this.stageIndex,
    required this.roundIndex,
    required this.roundCardIds,
    required this.cardPosition,
    required this.failedCardIds,
    this.phase = SessionPhase.inRound,
  });

  final int stageIndex;
  final int roundIndex;
  final List<String> roundCardIds;
  final int cardPosition;

  /// Cards that failed at least once in the current round (deduped); they seed
  /// the next round and are never cleared by a later pass.
  final List<String> failedCardIds;
  final SessionPhase phase;

  /// The card the cursor is on, or `null` once the session is complete.
  String? get currentCardId =>
      phase == SessionPhase.sessionComplete ||
          cardPosition >= roundCardIds.length
      ? null
      : roundCardIds[cardPosition];
}

/// The pure session advance state machine (WBS 5.6.3 domain part;
/// `answer-study-stage.md` master flow §3, `resume-study-session.md` §§58-60).
/// Given the current position and whether the just-answered card passed, it
/// computes the next position: advance within the round, else start the next
/// mastery round from the deduped failed set, else move to the next stage over
/// all session cards, else finish. It composes [RoundOrderPolicy] for every new
/// order and persists nothing.
class SessionAdvancePolicy {
  const SessionAdvancePolicy({
    RoundOrderPolicy orderPolicy = const RoundOrderPolicy(),
  }) : _orderPolicy = orderPolicy;

  final RoundOrderPolicy _orderPolicy;

  SessionPosition next({
    required String sessionId,
    required List<StudyModeType> stages,
    required List<String> allSessionCardIds,
    required SessionPosition current,
    required bool currentCardPassed,
  }) {
    final failed = _accumulateFailed(current, currentCardPassed);

    // More cards remain in the current round: advance the cursor.
    if (current.cardPosition + 1 < current.roundCardIds.length) {
      return SessionPosition(
        stageIndex: current.stageIndex,
        roundIndex: current.roundIndex,
        roundCardIds: current.roundCardIds,
        cardPosition: current.cardPosition + 1,
        failedCardIds: failed,
      );
    }

    // Round finished with failures: a new mastery round over the failed set.
    if (failed.isNotEmpty) {
      final nextRound = current.roundIndex + 1;
      return SessionPosition(
        stageIndex: current.stageIndex,
        roundIndex: nextRound,
        roundCardIds: _orderPolicy.order(
          sessionId: sessionId,
          modeId: stages[current.stageIndex].id,
          roundIndex: nextRound,
          cardIds: failed,
          previousSequence: current.roundCardIds,
        ),
        cardPosition: 0,
        failedCardIds: const <String>[],
      );
    }

    // Round clean: advance to the next stage, or finish the session.
    final nextStage = current.stageIndex + 1;
    if (nextStage >= stages.length) {
      return SessionPosition(
        stageIndex: current.stageIndex,
        roundIndex: current.roundIndex,
        roundCardIds: current.roundCardIds,
        cardPosition: current.cardPosition,
        failedCardIds: const <String>[],
        phase: SessionPhase.sessionComplete,
      );
    }
    // A new graded stage always starts at round 1 over all session cards.
    const newStageRound = 1;
    return SessionPosition(
      stageIndex: nextStage,
      roundIndex: newStageRound,
      roundCardIds: _orderPolicy.order(
        sessionId: sessionId,
        modeId: stages[nextStage].id,
        roundIndex: newStageRound,
        cardIds: allSessionCardIds,
        previousSequence: current.roundCardIds,
      ),
      cardPosition: 0,
      failedCardIds: const <String>[],
    );
  }

  List<String> _accumulateFailed(SessionPosition current, bool passed) {
    final currentCard = current.roundCardIds[current.cardPosition];
    if (passed || current.failedCardIds.contains(currentCard)) {
      return current.failedCardIds;
    }
    return <String>[...current.failedCardIds, currentCard];
  }
}
