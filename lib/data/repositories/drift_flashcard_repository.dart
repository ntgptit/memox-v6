import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart' as domain;
import 'package:memox_v6/domain/flashcard/card_text.dart';
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
          normalizeCardTerm(card.term),
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
  Future<List<domain.Flashcard>> duplicateCandidates({
    required String languagePairId,
    required String normalizedTerm,
  }) async {
    final rows = await _database.flashcardDao
        .findDuplicateCandidates(languagePairId, normalizedTerm)
        .get();
    return rows.map((row) => row.toDomain()).toList();
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

  // --- Additional translations (5.3.1B) -------------------------------

  @override
  Future<List<CardTranslation>> translationsOf(String cardId) async {
    final rows = await _database.flashcardDao
        .listTranslationsForCard(cardId)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> addCardTranslation(
    CardTranslation translation, {
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcard_translations', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.insertTranslation(
          translation.id,
          translation.cardId,
          translation.languageCode,
          translation.text,
          translation.displayOrder,
          epoch,
          epoch,
        );
        await _database.flashcardDao.touchFlashcardVersion(
          epoch,
          translation.cardId,
        );
      });
    });
  }

  @override
  Future<void> editCardTranslationText(
    String translationId, {
    required String cardId,
    required String text,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcard_translations', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.updateCardTranslationText(
          text,
          epoch,
          translationId,
        );
        await _database.flashcardDao.touchFlashcardVersion(epoch, cardId);
      });
    });
  }

  @override
  Future<void> removeCardTranslation(
    String translationId, {
    required String cardId,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcard_translations', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.deleteTranslation(translationId);
        // Keep positions contiguous after Save
        // (manage-card-translations.md section 5).
        final survivors = await _database.flashcardDao
            .listTranslationsForCard(cardId)
            .get();
        for (var i = 0; i < survivors.length; i++) {
          await _database.flashcardDao.parkCardTranslationOrder(
            (i + 1).toDouble(),
            epoch,
            survivors[i].id,
          );
        }
        for (var i = 0; i < survivors.length; i++) {
          await _database.flashcardDao.setCardTranslationOrder(
            i,
            epoch,
            survivors[i].id,
          );
        }
        await _database.flashcardDao.touchFlashcardVersion(epoch, cardId);
      });
    });
  }

  @override
  Future<void> reorderCardTranslations(
    String cardId, {
    required List<String> orderedTranslationIds,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcard_translations', () async {
      await _database.transaction(() async {
        for (var i = 0; i < orderedTranslationIds.length; i++) {
          await _database.flashcardDao.parkCardTranslationOrder(
            (i + 1).toDouble(),
            epoch,
            orderedTranslationIds[i],
          );
        }
        for (var i = 0; i < orderedTranslationIds.length; i++) {
          await _database.flashcardDao.setCardTranslationOrder(
            i,
            epoch,
            orderedTranslationIds[i],
          );
        }
        await _database.flashcardDao.touchFlashcardVersion(epoch, cardId);
      });
    });
  }

  // --- Tags (TAG-001..006) --------------------------------------------

  @override
  Future<List<CardTag>> tagsOf(String cardId) async {
    final rows = await _database.flashcardDao.listTagsForCard(cardId).get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<CardTag> resolveTagByLabel({
    required String displayName,
    required String normalizedName,
    required String newTagId,
    required DateTime now,
  }) async {
    final existing = await _database.flashcardDao
        .findTagByNormalizedName(normalizedName)
        .getSingleOrNull();
    if (existing != null) return existing.toDomain();

    final epoch = now.millisecondsSinceEpoch;
    try {
      await _database.flashcardDao.insertTag(
        newTagId,
        displayName,
        normalizedName,
        epoch,
        epoch,
      );
    } on Exception {
      // Concurrent creation of the same normalized label resolves
      // through the unique constraint to the winner's tag
      // (manage-card-tags.md).
      final winner = await _database.flashcardDao
          .findTagByNormalizedName(normalizedName)
          .getSingleOrNull();
      if (winner != null) return winner.toDomain();
      rethrow;
    }
    final created = await _database.flashcardDao
        .findTagByNormalizedName(normalizedName)
        .getSingle();
    return created.toDomain();
  }

  @override
  Future<void> attachCardTag(
    String cardId, {
    required String tagId,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcard_tags', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.attachTag(cardId, tagId, epoch);
        await _database.flashcardDao.touchFlashcardVersion(epoch, cardId);
      });
    });
  }

  @override
  Future<void> detachCardTag(
    String cardId, {
    required String tagId,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcard_tags', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.detachTag(cardId, tagId);
        await _database.flashcardDao.touchFlashcardVersion(epoch, cardId);
      });
    });
  }

  @override
  Future<bool> deleteTagIfUnused(String tagId) {
    return mapSqliteConflicts(entity: 'tags', () async {
      return _database.transaction(() async {
        final usage = await _database.flashcardDao
            .countTagAssociations(tagId)
            .getSingle();
        if (usage > 0) return false;
        await _database.flashcardDao.deleteTag(tagId);
        return true;
      });
    });
  }

  // --- Audio refs -----------------------------------------------------

  @override
  Future<List<CardAudioRef>> audioRefsOf(String cardId) async {
    final rows = await _database.flashcardDao
        .listAudioRefsForCard(cardId)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> addCardAudioRef(CardAudioRef ref, {required DateTime now}) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'card_audio_refs', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.insertAudioRef(
          ref.id,
          ref.cardId,
          ref.languageCode,
          ref.assetId,
          ref.provider,
          epoch,
          epoch,
        );
        await _database.flashcardDao.touchFlashcardVersion(epoch, ref.cardId);
      });
    });
  }

  @override
  Future<void> removeCardAudioRef(
    String refId, {
    required String cardId,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'card_audio_refs', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.deleteAudioRef(refId);
        await _database.flashcardDao.touchFlashcardVersion(epoch, cardId);
      });
    });
  }

  @override
  Future<domain.Flashcard> editCardContent(
    String cardId, {
    required String term,
    required String normalizedTerm,
    required String primaryMeaning,
    required int expectedContentVersion,
    required DateTime now,
  }) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcards', () async {
      return _database.transaction(() async {
        final row = await _database.flashcardDao
            .findFlashcardById(cardId)
            .getSingleOrNull();
        if (row == null) {
          throw ValidationFailure(field: 'cardId', code: 'not-found');
        }
        if (row.contentVersion != expectedContentVersion) {
          throw ConflictFailure(entity: 'flashcards', code: 'stale-version');
        }
        await _database.flashcardDao.updateFlashcardContent(
          term,
          normalizedTerm,
          primaryMeaning,
          epoch,
          cardId,
        );
        final updated = await _database.flashcardDao
            .findFlashcardById(cardId)
            .getSingle();
        return updated.toDomain();
      });
    });
  }

  @override
  Future<void> deleteCardCascade(String cardId, {required DateTime now}) {
    final epoch = now.millisecondsSinceEpoch;
    return mapSqliteConflicts(entity: 'flashcards', () async {
      await _database.transaction(() async {
        await _database.flashcardDao.deleteTranslationsForCard(cardId);
        await _database.flashcardDao.deleteTagAssociationsForCard(cardId);
        await _database.flashcardDao.deleteAudioRefsForCard(cardId);
        await _database.learningProgressDao.deleteProgressByCard(cardId);
        await _database.flashcardDao.softDeleteFlashcard(epoch, epoch, cardId);
      });
    });
  }
}
