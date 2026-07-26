import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/skipped_card_reason.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/study_modes/round_order_policy.dart';

/// Moves the session past a card that is no longer askable
/// (ST-CONTENT-CHANGE-v1 ST-CHG-005, ST-CHG-006).
///
/// A session's cards are frozen at start, so a card deleted or hidden after
/// the snapshot is still sitting in the queue with its text intact. The
/// snapshot is what keeps a *running* session coherent, but it is not licence
/// to ask about a card the learner has since deleted — and grading it would
/// schedule review for a card that no longer exists.
///
/// The skip commits like any other advance: no attempt is written, so the card
/// leaves the accuracy denominator and gets no schedule (ST-CHG-010), and the
/// position moves to the next card in the committed order. Nothing is
/// substituted in its place.
///
/// The reason is not stored anywhere. It does not need to be: a delete is a
/// tombstone (`deleted_at`) and a hide is a flag, so the row that explains the
/// skip is still in the store and still says why, for as long as the card
/// exists at all.
class SkipUnavailableCardUseCase {
  const SkipUnavailableCardUseCase({
    required StudySessionRepository sessions,
    required FlashcardRepository cards,
    required AppClock clock,
    SessionAdvancePolicy advancePolicy = const SessionAdvancePolicy(),
  }) : _sessions = sessions,
       _cards = cards,
       _clock = clock,
       _advancePolicy = advancePolicy;

  final StudySessionRepository _sessions;
  final FlashcardRepository _cards;
  final AppClock _clock;
  final SessionAdvancePolicy _advancePolicy;

  /// The reason the current card was skipped, or null when it is still
  /// askable (or there is no current card).
  Future<SkippedCardReason?> call(StudyRuntimeState current) async {
    final cardId = current.position.currentCardId;
    if (cardId == null) return null;

    final live = await _cards.findById(cardId);
    final reason = _reasonFor(live);
    if (reason == null) return null;

    final position = current.position;
    final sessionId = current.session.id;
    // Advanced as passed, which here means only "does not seed the retry
    // round". A skipped card must not come back for a second attempt it can
    // no longer have, and it must not be recorded as wrong — ST-CHG-005 is
    // explicit that a skip does not fake an outcome either way.
    final next = _advancePolicy.next(
      sessionId: sessionId,
      stages: current.stages,
      allSessionCardIds: current.allCardIdsInBaseOrder,
      current: position,
      currentCardPassed: true,
    );
    final now = _clock.nowUtc();

    await _sessions.saveCheckpoint(
      SessionCheckpoint(
        id: 'cp-$sessionId',
        sessionId: sessionId,
        stageIndex: next.stageIndex,
        roundIndex: next.roundIndex,
        cardPosition: next.cardPosition,
        failedCardIds: next.failedCardIds,
        timerStateJson: '{}',
        stateVersion: position.roundIndex + position.cardPosition + 1,
        updatedAt: now,
      ),
      newRoundOrder: next.roundIndex == position.roundIndex
          ? null
          : SessionRoundOrder(
              id: 'ro-$sessionId-${next.roundIndex}',
              sessionId: sessionId,
              roundIndex: next.roundIndex,
              seed: roundOrderSeed(
                sessionId: sessionId,
                modeId: current.stages[next.stageIndex].id,
                roundIndex: next.roundIndex,
              ),
              cardIds: next.roundCardIds,
            ),
    );
    return reason;
  }

  /// A row that is gone or tombstoned reads as deleted; a hidden one keeps
  /// its content but leaves the queues, which is the same thing from inside a
  /// session (`hide-flashcard.md`: only fresh candidate queues exclude it —
  /// a running session is what this rule adds).
  SkippedCardReason? _reasonFor(Flashcard? live) {
    if (live == null || live.isDeleted) {
      return SkippedCardReason.deletedAfterSnapshot;
    }
    if (live.isHidden) return SkippedCardReason.hiddenAfterSnapshot;
    return null;
  }
}
