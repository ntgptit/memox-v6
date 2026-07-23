import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/domain/deck/deck.dart' as domain;
import 'package:memox_v6/domain/deck/deck_summary.dart' as domain;
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Drift-backed [DeckRepository] (WBS 4.6A). Every write runs through
/// the conflict mapper, so the 4.3 trigger aborts arrive as typed
/// `ConflictFailure`s with their stable codes.
class DriftDeckRepository implements DeckRepository {
  DriftDeckRepository(this._database, this._clock);

  final db.AppDatabase _database;
  final AppClock _clock;

  @override
  Future<void> createDeck(domain.Deck deck) {
    return mapSqliteConflicts(entity: 'decks', () async {
      await _database.transaction(() async {
        await _database.deckDao.insertDeck(
          deck.id,
          deck.languagePairId,
          deck.parentId,
          deck.name,
          deck.normalizedName,
          deck.createdAt.millisecondsSinceEpoch,
          deck.updatedAt.millisecondsSinceEpoch,
        );
        final description = deck.description;
        if (description != null) {
          await _database.deckDao.updateDeckDescription(
            description,
            deck.updatedAt.millisecondsSinceEpoch,
            deck.id,
          );
        }
      });
    });
  }

  @override
  Future<domain.Deck?> findById(String id) async {
    final row = await _database.deckDao.findDeckById(id).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Stream<List<domain.Deck>> watchRoots(String languagePairId) {
    return _database.deckDao
        .watchRootDecks(languagePairId)
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Stream<List<domain.DeckSummary>> watchRootSummaries(String languagePairId) {
    // Due-ness is measured against subscription time; the library refreshes
    // on re-entry rather than ticking per second. drift types this bound
    // variable as text, so the query `CAST`s it back to the integer epoch
    // it is compared against.
    final nowUtc = _clock.nowUtc().millisecondsSinceEpoch.toString();
    return _database.deckDao
        .watchRootDeckSummaries(nowUtc, languagePairId)
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Stream<List<domain.Deck>> watchChildren(String parentId) {
    return _database.deckDao
        .watchChildDecks(parentId)
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<void> rename(
    String deckId, {
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'decks', () async {
      await _database.deckDao.renameDeck(
        name,
        normalizedName,
        updatedAt.millisecondsSinceEpoch,
        deckId,
      );
    });
  }

  @override
  Future<void> move(
    String deckId, {
    required String? newParentId,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'decks', () async {
      await _database.deckDao.moveDeck(
        newParentId,
        updatedAt.millisecondsSinceEpoch,
        deckId,
      );
    });
  }

  @override
  Future<DeckContentCounts> contentCounts(String deckId) async {
    final childDecks = await _database.deckDao
        .countChildDecks(deckId)
        .getSingle();
    final activeCards = await _database.flashcardDao
        .countActiveFlashcardsInDeck(deckId)
        .getSingle();
    return DeckContentCounts(
      childDeckCount: childDecks,
      activeCardCount: activeCards,
    );
  }

  @override
  Future<int> countSubtreeCards(String deckId) {
    return _database.deckDao.countSubtreeCards(deckId).getSingle();
  }

  @override
  Future<int> countSubtreeDecks(String deckId) {
    return _database.deckDao.countSubtreeDecks(deckId).getSingle();
  }

  @override
  Future<int> countForLanguagePair(String languagePairId) {
    return _database.deckDao
        .countDecksForLanguagePair(languagePairId)
        .getSingle();
  }

  @override
  Future<void> delete(String deckId) {
    return mapSqliteConflicts(entity: 'decks', () async {
      await _database.deckDao.deleteDeck(deckId);
    });
  }
}
