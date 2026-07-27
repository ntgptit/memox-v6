import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/domain/deck/deck.dart' as domain;
import 'package:memox_v6/domain/deck/move_destination.dart' as domain;
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
  Future<List<domain.DeckSummary>> recentSummaries(
    String languagePairId, {
    required int limit,
  }) async {
    // Same read-time due-ness contract as the watching queries above.
    final nowUtc = _clock.nowUtc().millisecondsSinceEpoch.toString();
    final rows = await _database.deckDao
        .recentRootDeckSummaries(nowUtc, languagePairId, limit)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Stream<List<domain.DeckSummary>> watchChildSummaries(String parentId) {
    // Same subscription-time due-ness contract as watchRootSummaries.
    final nowUtc = _clock.nowUtc().millisecondsSinceEpoch.toString();
    return _database.deckDao
        .watchChildDeckSummaries(nowUtc, parentId)
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
  Future<List<domain.Deck>> ancestors(String deckId) async {
    final rows = await _database.deckDao.deckAncestors(deckId).get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<domain.MoveDestination>> moveDestinationCandidates(
    String languagePairId, {
    required String movingDeckId,
  }) async {
    final rows = await _database.deckDao
        .moveDestinationCandidates(movingDeckId, languagePairId)
        .get();
    return rows
        .map(
          (row) => domain.MoveDestination(
            deck: row.toDomain(),
            ineligibility: domain.MoveIneligibility.parse(row.ineligibility),
          ),
        )
        .toList();
  }

  @override
  Future<List<domain.Deck>> moveDestinations(
    String languagePairId, {
    required String movingDeckId,
  }) async {
    final rows = await _database.deckDao
        .moveDestinationDecks(movingDeckId, languagePairId)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<domain.Deck>> cardMoveTargets(
    String languagePairId, {
    required String excludeDeckId,
  }) async {
    final rows = await _database.deckDao
        .cardMoveDestinationDecks(languagePairId, excludeDeckId)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> editMetadata(
    String deckId, {
    required String name,
    required String normalizedName,
    required String? description,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'decks', () async {
      await _database.deckDao.editDeckMetadata(
        name,
        normalizedName,
        description,
        description == null ? null : StringUtils.comparisonKey(description),
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
  Future<int> countSubtreeStudiedCards(String deckId) async {
    final row = await _database.deckDao
        .countSubtreeStudiedCards(deckId)
        .getSingle();
    return row;
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
      // `delete-deck.md` §3 node G: "Remove subtree atomically", and §1:
      // "Parent delete áp dụng toàn descendants; failure không xóa một phần."
      //
      // This was a single `DELETE FROM decks WHERE id = ?`. `flashcards`
      // references `decks` with no ON DELETE CASCADE, so deleting any deck
      // that held a card raised a foreign-key violation — every populated
      // deck was undeletable. Descendants were not removed either.
      //
      // One transaction so a failure removes nothing. Cards go first because
      // the deck rows are what they point at; translations, tags, audio refs
      // and learning progress all cascade from the card.
      // Order is forced by the references, none of which cascade to a deck:
      // progress points at an attempt, attempts point at cards, sessions
      // point at decks. That chain is why a deck which had ever been studied
      // could not be deleted, though being used is the usual reason to want
      // it gone.
      //
      // The session history of a deleted deck goes with it. The learner's
      // streak and daily goals do not: those are keyed by local date in their
      // own tables and never referenced the deck.
      //
      // This contradicts ST-CHG-002, which says a session whose snapshot is
      // sufficient should be allowed to *finish* after its deck is deleted.
      // The schema is what prevents it: sessions, their card snapshots and
      // their relearn items are anchored to decks and cards by foreign key,
      // so honouring the table means dropping three of them and accepting
      // rows that reference deleted content. That trade-off is recorded as
      // `int-34` and is the owner's to make; until then the confirm names
      // the session it will destroy rather than the delete pretending
      // otherwise.
      await _database.transaction(() async {
        await _database.deckDao.clearTerminalAttemptRefsInDecks(deckId);
        await _database.deckDao.deleteAttemptsInDecks(deckId);
        await _database.deckDao.deleteSessionsInDecks(deckId);
        await _database.deckDao.deleteFlashcardsInDecks(deckId);
        await _database.deckDao.deleteDeckSubtree(deckId);
      });
    });
  }
}
