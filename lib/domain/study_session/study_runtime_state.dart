import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';

/// The immutable read model a study screen renders (WBS 5.6.3). It is assembled
/// from the committed session snapshot + checkpoint + current round order, so it
/// is a pure projection of persisted state — no UI memory, replayable on resume
/// (`resume-study-session.md` §7).
class StudyRuntimeState {
  const StudyRuntimeState({
    required this.session,
    required this.stages,
    required this.position,
    required this.cardsById,
  });

  /// Assemble the runtime from committed pieces. With no checkpoint the session
  /// has just started: the position is the first card of the initial order
  /// (stage 0), matching the "checkpoint points at Stage 1, first card" start
  /// contract without needing a persisted checkpoint (`start-study-session.md`
  /// §7; GAP-B).
  factory StudyRuntimeState.assemble({
    required StudySession session,
    required List<StudyModeType> stages,
    required List<SessionCardSnapshot> cardSnapshots,
    required SessionRoundOrder currentOrder,
    SessionCheckpoint? checkpoint,
  }) {
    final position = checkpoint == null
        ? SessionPosition(
            stageIndex: 0,
            roundIndex: currentOrder.roundIndex,
            roundCardIds: currentOrder.cardIds,
            cardPosition: 0,
            failedCardIds: const <String>[],
          )
        : SessionPosition(
            stageIndex: checkpoint.stageIndex,
            roundIndex: checkpoint.roundIndex,
            roundCardIds: currentOrder.cardIds,
            cardPosition: checkpoint.cardPosition,
            failedCardIds: checkpoint.failedCardIds,
          );
    return StudyRuntimeState(
      session: session,
      stages: stages,
      position: position,
      cardsById: <String, SessionCardSnapshot>{
        for (final card in cardSnapshots) card.cardId: card,
      },
    );
  }

  final StudySession session;
  final List<StudyModeType> stages;
  final SessionPosition position;
  final Map<String, SessionCardSnapshot> cardsById;

  /// The mode the current stage runs.
  StudyModeType get currentMode => stages[position.stageIndex];

  /// The card snapshot under the cursor, or `null` once the session completes.
  SessionCardSnapshot? get currentCard {
    final cardId = position.currentCardId;
    return cardId == null ? null : cardsById[cardId];
  }

  /// Whether every stage is finished.
  bool get isComplete => position.phase == SessionPhase.sessionComplete;

  /// Cards pinned in the session snapshot.
  int get totalCards => cardsById.length;

  /// Cards answered in the current round so far (the cursor).
  int get answeredInRound => position.cardPosition;

  /// Cards in the current round.
  int get roundCardCount => position.roundCardIds.length;

  /// Every session card id in the stable snapshot base order (by displayOrder) —
  /// the membership a new stage's round-1 order shuffles over.
  List<String> get allCardIdsInBaseOrder {
    final ordered = cardsById.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return ordered.map((card) => card.cardId).toList();
  }
}
