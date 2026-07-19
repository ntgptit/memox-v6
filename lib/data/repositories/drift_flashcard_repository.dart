import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart' as domain;
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/new_card_content.dart';

/// Drift-backed [FlashcardRepository] (WBS 4.6A).
class DriftFlashcardRepository implements FlashcardRepository {
  DriftFlashcardRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> createCard(NewCardContent content) {
    final card = content.card;
    return mapSqliteConflicts(entity: 'flashcards', () async {
      await _database.transaction(() async {
        final existing = await _database.flashcardDao
            .findFlashcardById(card.id)
            .getSingleOrNull();
        // The card id is the operation's idempotency key: a retry that
        // finds it stored means the earlier transaction committed.
        if (existing != null) return;

        await _database.flashcardDao.insertFlashcard(
          card.id,
          card.deckId,
          card.term,
          card.primaryMeaning,
          card.createdAt.millisecondsSinceEpoch,
          card.updatedAt.millisecondsSinceEpoch,
        );
        for (final translation in content.translations) {
          await _database.flashcardDao.insertTranslation(
            translation.id,
            card.id,
            translation.languageCode,
            translation.text,
            translation.displayOrder,
            card.createdAt.millisecondsSinceEpoch,
            card.createdAt.millisecondsSinceEpoch,
          );
        }
        for (final tagId in content.tagIds) {
          await _database.flashcardDao.attachTag(
            card.id,
            tagId,
            card.createdAt.millisecondsSinceEpoch,
          );
        }
        for (final audioRef in content.audioRefs) {
          await _database.flashcardDao.insertAudioRef(
            audioRef.id,
            card.id,
            audioRef.languageCode,
            audioRef.assetId,
            audioRef.provider,
            card.createdAt.millisecondsSinceEpoch,
            card.createdAt.millisecondsSinceEpoch,
          );
        }
        // Initial Box 0 progress: no due date until the policy schedules.
        await _database.learningProgressDao.insertProgress(
          'progress-${card.id}',
          card.id,
          0,
          null,
          card.createdAt.millisecondsSinceEpoch,
          card.createdAt.millisecondsSinceEpoch,
        );
      });
    });
  }

  @override
  Future<domain.Flashcard?> findById(String id) async {
    final row = await _database.flashcardDao
        .findFlashcardById(id)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<domain.Flashcard>> pageByDeck(
    String deckId, {
    required int limit,
    required int offset,
  }) async {
    final rows = await _database.flashcardDao
        .pageFlashcardsByDeck(deckId, limit, offset)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Stream<List<domain.Flashcard>> watchByDeck(String deckId) {
    return _database.flashcardDao
        .watchFlashcardsByDeck(deckId)
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<void> setHidden(
    String cardId, {
    required bool isHidden,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'flashcards', () async {
      await _database.flashcardDao.setFlashcardHidden(
        isHidden ? 1 : 0,
        updatedAt.millisecondsSinceEpoch,
        cardId,
      );
    });
  }

  @override
  Future<void> softDelete(String cardId, {required DateTime deletedAt}) {
    return mapSqliteConflicts(entity: 'flashcards', () async {
      await _database.flashcardDao.softDeleteFlashcard(
        deletedAt.millisecondsSinceEpoch,
        deletedAt.millisecondsSinceEpoch,
        cardId,
      );
    });
  }

  @override
  Future<void> restore(String cardId, {required DateTime updatedAt}) {
    return mapSqliteConflicts(entity: 'flashcards', () async {
      await _database.flashcardDao.restoreFlashcard(
        updatedAt.millisecondsSinceEpoch,
        cardId,
      );
    });
  }

  @override
  Future<void> move(
    String cardId, {
    required String targetDeckId,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'flashcards', () async {
      await _database.flashcardDao.moveFlashcard(
        targetDeckId,
        updatedAt.millisecondsSinceEpoch,
        cardId,
      );
    });
  }
}
