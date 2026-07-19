import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/mappers/primitive_mapper.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_relearn_item.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';

/// Session row → domain mappers (WBS 4.5). Enum parsing raises typed
/// [DataCorruptionFailure]s for values outside the schema CHECK sets.

extension StudySessionRowMapper on db.StudySession {
  StudySession toDomain() => StudySession(
    id: id,
    type: SessionType.parse(sessionType),
    deckId: deckId,
    scope: SessionScope.parse(scope),
    state: SessionState.parse(state),
    revision: revision,
    snapshotVersion: snapshotVersion,
    scheduleSrs: storedBool(
      scheduleSrs,
      entity: 'study_sessions',
      field: 'schedule_srs',
    ),
    startedAt: utcDateTime(startedAt),
    finalizedAt: utcDateTimeOrNull(finalizedAt),
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension SessionCardSnapshotRowMapper on db.StudySessionCard {
  SessionCardSnapshot toDomain() => SessionCardSnapshot(
    id: id,
    sessionId: sessionId,
    cardId: cardId,
    displayOrder: displayOrder,
    term: termSnapshot,
    meaning: meaningSnapshot,
    contentVersion: contentVersion,
    progressBox: progressBoxSnapshot,
    progressRevision: progressRevision,
  );
}

extension SessionCheckpointRowMapper on db.StudyCheckpoint {
  SessionCheckpoint toDomain() => SessionCheckpoint(
    id: id,
    sessionId: sessionId,
    stageIndex: stageIndex,
    roundIndex: roundIndex,
    cardPosition: cardPosition,
    failedCardIds: storedStringList(
      failedSetJson,
      entity: 'study_checkpoints',
      field: 'failed_set_json',
    ),
    timerStateJson: timerStateJson,
    stateVersion: stateVersion,
    updatedAt: utcDateTime(updatedAt),
  );
}

extension SessionRoundOrderRowMapper on db.StudyRoundOrder {
  SessionRoundOrder toDomain() => SessionRoundOrder(
    id: id,
    sessionId: sessionId,
    roundIndex: roundIndex,
    seed: seed,
    cardIds: storedStringList(
      cardOrderJson,
      entity: 'study_round_orders',
      field: 'card_order_json',
    ),
  );
}

extension SessionRelearnItemRowMapper on db.SessionRelearnItem {
  SessionRelearnItem toDomain() => SessionRelearnItem(
    id: id,
    sessionId: sessionId,
    cardId: cardId,
    retryCount: retryCount,
  );
}

extension StudyAttemptRowMapper on db.StudyAttempt {
  StudyAttempt toDomain() => StudyAttempt(
    id: id,
    idempotencyKey: idempotencyKey,
    cardId: cardId,
    sessionId: sessionId,
    modeId: modeId,
    outcome: outcome,
    evidenceJson: evidenceJson,
    isTerminal: storedBool(
      isTerminal,
      entity: 'study_attempts',
      field: 'is_terminal',
    ),
    createdAt: utcDateTime(createdAt),
  );
}
