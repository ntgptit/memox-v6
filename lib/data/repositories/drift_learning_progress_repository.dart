import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/progress_mapper.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/study_candidates.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';

/// Drift-backed [LearningProgressRepository] (WBS 4.6B).
class DriftLearningProgressRepository implements LearningProgressRepository {
  DriftLearningProgressRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> applyScheduledOutcome({
    required StudyAttempt attempt,
    required int newBox,
    required DateTime? newDueAt,
    required int repetitionCount,
    required int lapseCount,
    required int expectedRevision,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'learning_progress', () async {
      await _database.transaction(() async {
        final replayed = await _database.studyAttemptDao
            .findAttemptByIdempotencyKey(attempt.idempotencyKey)
            .getSingleOrNull();
        // Exactly-once: a stored idempotency key means the earlier
        // transaction committed both the evidence and the schedule.
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

        final applied = await _database.learningProgressDao
            .updateProgressGuarded(
              newBox,
              newDueAt?.millisecondsSinceEpoch,
              repetitionCount,
              lapseCount,
              attempt.id,
              updatedAt.millisecondsSinceEpoch,
              attempt.cardId,
              expectedRevision,
            );
        if (applied == 0) {
          throw ConflictFailure(code: 'revision', entity: 'learning_progress');
        }
      });
    });
  }

  @override
  Future<void> resetCard(
    String cardId, {
    required String newProgressId,
    required DateTime at,
  }) {
    return mapSqliteConflicts(entity: 'learning_progress', () async {
      await _database.transaction(() async {
        await _database.learningProgressDao.deleteProgressByCard(cardId);
        await _database.learningProgressDao.insertProgress(
          newProgressId,
          cardId,
          0,
          null,
          at.millisecondsSinceEpoch,
          at.millisecondsSinceEpoch,
        );
      });
    });
  }

  @override
  Future<LearningProgress?> findByCard(String cardId) async {
    final row = await _database.learningProgressDao
        .findProgressByCard(cardId)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<LearningProgress> ensureInitialProgress({
    required String id,
    required String cardId,
    required DateTime nowUtc,
  }) async {
    // Idempotent: an existing state is returned untouched (never reset).
    final existing = await findByCard(cardId);
    if (existing != null) return existing;

    final ms = nowUtc.millisecondsSinceEpoch;
    await mapSqliteConflicts(
      entity: 'learning_progress',
      () => _database.learningProgressDao.initialiseCardProgress(
        id,
        cardId,
        ms,
        ms,
      ),
    );

    final created = await findByCard(cardId);
    if (created != null) return created;
    // `OR IGNORE` skipped without an existing row means the card was absent
    // (FK) — surface it rather than fabricate a state.
    throw StateError('ensureInitialProgress produced no row for card $cardId');
  }

  @override
  Future<StudyCandidates> studyCandidatesInScope({
    required String scopeDeckId,
    required DateTime nowUtc,
  }) async {
    final rows = await _database.learningProgressDao
        .studyCandidatesInScope(
          scopeDeckId,
          nowUtc.millisecondsSinceEpoch.toString(),
        )
        .get();
    final due = <String>[];
    final fresh = <String>[];
    for (final row in rows) {
      (row.isNew ? fresh : due).add(row.cardId);
    }
    return StudyCandidates(dueCardIds: due, newCardIds: fresh);
  }

  @override
  Future<List<LearningProgress>> pageDue(
    DateTime nowUtc, {
    required int limit,
    required int offset,
  }) async {
    final rows = await _database.learningProgressDao
        .pageDueProgress(nowUtc.millisecondsSinceEpoch, limit, offset)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<int> countDue(DateTime nowUtc) {
    return _database.learningProgressDao
        .countDueProgress(nowUtc.millisecondsSinceEpoch)
        .getSingle();
  }
}
