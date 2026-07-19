import 'dart:convert';

import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/session_mapper.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_relearn_item.dart'
    as domain;
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart' as domain;
import 'package:memox_v6/domain/study_session/study_session.dart' as domain;
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';

/// Drift-backed [StudySessionRepository] (WBS 4.6C).
class DriftStudySessionRepository implements StudySessionRepository {
  DriftStudySessionRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> startSession({
    required domain.StudySession session,
    required List<SessionCardSnapshot> cardSnapshots,
    required SessionRoundOrder initialOrder,
  }) {
    return mapSqliteConflicts(entity: 'study_sessions', () async {
      await _database.transaction(() async {
        final existing = await _database.studySessionDao
            .findSessionById(session.id)
            .getSingleOrNull();
        // The session id is the idempotency key: a stored row means the
        // earlier start committed its snapshots and order too.
        if (existing != null) return;

        await _database.studySessionDao.insertSession(
          session.id,
          session.type.dbValue,
          session.deckId,
          session.scope.dbValue,
          session.state.dbValue,
          session.scheduleSrs ? 1 : 0,
          session.startedAt.millisecondsSinceEpoch,
          session.createdAt.millisecondsSinceEpoch,
          session.updatedAt.millisecondsSinceEpoch,
        );
        for (final snapshot in cardSnapshots) {
          await _database.sessionSnapshotDao.insertSessionCard(
            snapshot.id,
            snapshot.sessionId,
            snapshot.cardId,
            snapshot.displayOrder,
            snapshot.term,
            snapshot.meaning,
            snapshot.contentVersion,
            snapshot.progressBox,
            snapshot.progressRevision,
            session.startedAt.millisecondsSinceEpoch,
          );
        }
        await _database.sessionSnapshotDao.insertRoundOrder(
          initialOrder.id,
          initialOrder.sessionId,
          initialOrder.roundIndex,
          initialOrder.seed,
          jsonEncode(initialOrder.cardIds),
          session.startedAt.millisecondsSinceEpoch,
        );
      });
    });
  }

  @override
  Future<domain.StudySession?> findById(String id) async {
    final row = await _database.studySessionDao
        .findSessionById(id)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Stream<domain.StudySession?> watchActive() {
    return _database.studySessionDao
        .watchActiveSession()
        .watchSingleOrNull()
        .map((row) => row?.toDomain());
  }

  @override
  Future<List<SessionCardSnapshot>> cardSnapshots(String sessionId) async {
    final rows = await _database.sessionSnapshotDao
        .listSessionCards(sessionId)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<SessionRoundOrder?> roundOrder(
    String sessionId,
    int roundIndex,
  ) async {
    final row = await _database.sessionSnapshotDao
        .findRoundOrder(sessionId, roundIndex)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> saveAttemptWithCheckpoint({
    required domain.StudyAttempt attempt,
    required SessionCheckpoint checkpoint,
  }) {
    return mapSqliteConflicts(entity: 'study_attempts', () async {
      await _database.transaction(() async {
        final replayed = await _database.studyAttemptDao
            .findAttemptByIdempotencyKey(attempt.idempotencyKey)
            .getSingleOrNull();
        // Replay: that transaction already persisted its checkpoint.
        if (replayed != null) return;

        await _database.studyAttemptDao.insertAttempt(
          attempt.id,
          attempt.idempotencyKey,
          attempt.cardId,
          attempt.sessionId,
          attempt.modeId,
          attempt.outcome,
          attempt.evidenceJson,
          attempt.isTerminal ? 1 : 0,
          attempt.createdAt.millisecondsSinceEpoch,
        );
        await _upsertCheckpoint(checkpoint);
      });
    });
  }

  @override
  Future<SessionCheckpoint?> checkpoint(String sessionId) async {
    final row = await _database.sessionCheckpointDao
        .findCheckpoint(sessionId)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> finalizeSession({
    required String sessionId,
    required int expectedRevision,
    required SessionState terminalState,
    required DateTime finalizedAt,
    GoalDayProgress? goalContribution,
    StreakDay? streakContribution,
  }) {
    return mapSqliteConflicts(entity: 'study_sessions', () async {
      await _database.transaction(() async {
        final applied = await _database.studySessionDao
            .updateSessionStateGuarded(
              terminalState.dbValue,
              finalizedAt.millisecondsSinceEpoch,
              finalizedAt.millisecondsSinceEpoch,
              sessionId,
              expectedRevision,
            );
        if (applied == 0) {
          final current = await _database.studySessionDao
              .findSessionById(sessionId)
              .getSingleOrNull();
          // Exactly-once: a session already in the requested terminal
          // state means an earlier finalize committed its
          // contributions as well.
          if (current?.state == terminalState.dbValue) return;
          throw ConflictFailure(code: 'revision', entity: 'study_sessions');
        }

        final goal = goalContribution;
        if (goal != null) {
          await _database.studyGoalDao.upsertDayProgress(
            goal.id,
            goal.localDate,
            goal.timezoneId,
            goal.goalId,
            goal.qualifiedCardCount,
            goal.targetSnapshot,
            goal.isMet ? 1 : 0,
            goal.updatedAt.millisecondsSinceEpoch,
            goal.updatedAt.millisecondsSinceEpoch,
          );
        }
        final streak = streakContribution;
        if (streak != null) {
          await _database.streakDao.recordStreakDay(
            streak.id,
            streak.localDate,
            streak.timezoneId,
            streak.qualifiedSource,
            finalizedAt.millisecondsSinceEpoch,
          );
        }
      });
    });
  }

  @override
  Future<void> addRelearnItem(
    domain.SessionRelearnItem item, {
    required DateTime recordedAt,
  }) {
    return mapSqliteConflicts(entity: 'session_relearn_items', () async {
      await _database.sessionCheckpointDao.addRelearnItem(
        item.id,
        item.sessionId,
        item.cardId,
        recordedAt.millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<List<domain.SessionRelearnItem>> relearnItems(String sessionId) async {
    final rows = await _database.sessionCheckpointDao
        .listRelearnItems(sessionId)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<void> _upsertCheckpoint(SessionCheckpoint checkpoint) {
    return _database.sessionCheckpointDao.upsertCheckpoint(
      checkpoint.id,
      checkpoint.sessionId,
      checkpoint.stageIndex,
      checkpoint.roundIndex,
      checkpoint.cardPosition,
      jsonEncode(checkpoint.failedCardIds),
      checkpoint.timerStateJson,
      checkpoint.stateVersion,
      checkpoint.updatedAt.millisecondsSinceEpoch,
    );
  }
}
