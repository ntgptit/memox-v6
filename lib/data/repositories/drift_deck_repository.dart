import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/domain/deck/deck.dart' as domain;
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Drift-backed [DeckRepository] (WBS 4.6A). Every write runs through
/// the conflict mapper, so the 4.3 trigger aborts arrive as typed
/// `ConflictFailure`s with their stable codes.
class DriftDeckRepository implements DeckRepository {
  DriftDeckRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> createDeck(domain.Deck deck) {
    return mapSqliteConflicts(entity: 'decks', () async {
      await _database.deckDao.insertDeck(
        deck.id,
        deck.languagePairId,
        deck.parentId,
        deck.name,
        deck.normalizedName,
        deck.createdAt.millisecondsSinceEpoch,
        deck.updatedAt.millisecondsSinceEpoch,
      );
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
