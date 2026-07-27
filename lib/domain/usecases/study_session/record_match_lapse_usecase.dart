import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// Commits a Match lapse to the session checkpoint the moment it happens
/// (WBS 5.6.12; `exit-study-session.md` §5, `match-terms-and-meanings.md` §4).
///
/// A Match round writes no attempt until the whole board is cleared, because
/// the board resolves pairs in free order while the session cursor is
/// sequential. That batching is sound for the attempts themselves; what it
/// also delayed was the *failed set*, and that set is not the board's private
/// state — §5's last line puts "next-round failed set đã commit" in the paused
/// checkpoint, and §4 makes a lapse sticky for the round.
///
/// So a learner who got a pair wrong and then left had the lapse forgotten:
/// the round restarted, they matched it correctly the second time, and the
/// card completed the stage without ever appearing in a retry round (`int-83`).
/// Writing the card into the checkpoint's failed set as it lapses is enough to
/// close that, without a durable board: the advance policy accumulates onto
/// the committed set rather than replacing it, so the round-end flush keeps
/// what this wrote.
///
/// Idempotent per card (§4: "không duplicate"), and a no-op when the session
/// has no checkpoint yet — there is no committed position to amend, and
/// inventing one would put the session somewhere it has never been.
class RecordMatchLapseUseCase {
  const RecordMatchLapseUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<void> call({required String sessionId, required String cardId}) async {
    final current = await _sessions.checkpoint(sessionId);
    if (current == null) return;
    if (current.failedCardIds.contains(cardId)) return;

    await _sessions.saveCheckpoint(
      SessionCheckpoint(
        id: current.id,
        sessionId: current.sessionId,
        stageIndex: current.stageIndex,
        roundIndex: current.roundIndex,
        cardPosition: current.cardPosition,
        failedCardIds: <String>[...current.failedCardIds, cardId],
        timerStateJson: current.timerStateJson,
        stateVersion: current.stateVersion + 1,
        updatedAt: current.updatedAt,
      ),
    );
  }
}
