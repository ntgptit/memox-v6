import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/progress_mapper.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/study_candidates.dart';
import 'package:memox_v6/domain/learning_progress/study_queue_counts.dart';
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
    required DateTime? srsActivatedAt,
    required DateTime lastReviewedAt,
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
        //
        // The key column is globally unique, so a key minted for one card
        // would silently swallow a grade for another — no write, no error,
        // the caller believing it succeeded. Today's keys are card-scoped by
        // construction (`terminal:<session>:<card>` and the stage key's
        // card position), so this cannot fire; it exists so that if that
        // ever stops being true, the result is a typed failure rather than a
        // lost review.
        if (replayed != null) {
          if (replayed.cardId != attempt.cardId) {
            throw ValidationFailure(
              field: 'idempotencyKey',
              code: 'card-mismatch',
            );
          }
          return;
        }

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
              srsActivatedAt?.millisecondsSinceEpoch,
              lastReviewedAt.millisecondsSinceEpoch,
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
  Future<LearningProgress> initialiseNew(
    String cardId, {
    required String progressId,
    required DateTime at,
  }) {
    return mapSqliteConflicts(entity: 'learning_progress', () async {
      return _database.transaction(() async {
        await _database.learningProgressDao.insertNewProgressIfAbsent(
          progressId,
          cardId,
          at.millisecondsSinceEpoch,
          at.millisecondsSinceEpoch,
        );
        // Read back inside the same transaction: the insert is
        // OR IGNORE, so this is what distinguishes "created" from
        // "already there" — and either way the caller gets the stored
        // state, never a locally built one.
        final row = await _database.learningProgressDao
            .findProgressByCard(cardId)
            .getSingleOrNull();
        if (row == null) {
          throw ConflictFailure(
            code: 'progress-missing',
            entity: 'learning_progress',
          );
        }
        return row.toDomain();
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
  Future<int> resetSubtreeProgress(
    String deckId, {
    required IdGenerator idGenerator,
    required DateTime at,
  }) {
    return mapSqliteConflicts(entity: 'learning_progress', () async {
      return _database.transaction(() async {
        final cardIds = await _database.deckDao.subtreeCardIds(deckId).get();
        final millis = at.millisecondsSinceEpoch;
        for (final cardId in cardIds) {
          await _database.learningProgressDao.deleteProgressByCard(cardId);
          await _database.learningProgressDao.insertProgress(
            idGenerator.newId(),
            cardId,
            0,
            null,
            millis,
            millis,
          );
        }
        return cardIds.length;
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
  Future<StudyQueueCounts> countDeckQueues(
    String deckId, {
    required DateTime nowUtc,
  }) async {
    // drift types this bound variable as text, so the query CASTs it
    // back to the integer epoch it compares against.
    final row = await _database.learningProgressDao
        .countDeckQueues(deckId, nowUtc.millisecondsSinceEpoch.toString())
        .getSingle();
    return StudyQueueCounts(dueCount: row.dueCount, newCount: row.newCount);
  }

  @override
  Future<StudyQueueCounts> countLibraryQueues(
    String languagePairId, {
    required DateTime nowUtc,
  }) async {
    final row = await _database.learningProgressDao
        .countLibraryQueues(
          nowUtc.millisecondsSinceEpoch.toString(),
          languagePairId,
        )
        .getSingle();
    return StudyQueueCounts(dueCount: row.dueCount, newCount: row.newCount);
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
