import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_search_repository.dart';
import 'package:memox_v6/domain/search/search_result.dart';

/// WBS 10.1 — the Library search read-model ranks exact → prefix → contained,
/// cards before decks, excluding hidden/deleted and other pairs (search-rank-v1).
void main() {
  late db.AppDatabase database;
  late DriftSearchRepository search;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    search = DriftSearchRepository(database);
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.languagePairDao.insertLanguagePair(
      'lp2',
      'en',
      'ko',
      'en|ko',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Deck',
      'deck',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'apples',
      'lp1',
      null,
      'Apples',
      'apples',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c_app',
      'root',
      'app',
      'app',
      'ứng dụng',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c_apple',
      'root',
      'apple',
      'apple',
      'quả táo',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<List<SearchResult>> run(String query) =>
      search.searchLibrary('lp1', cardQuery: query, deckQuery: query);

  test('ranks exact then prefix, with cards before decks', () async {
    final results = await run('app');
    expect(results.map((r) => r.id).toList(), ['c_app', 'c_apple', 'apples']);
    expect(results.map((r) => r.type).toList(), [
      SearchResultType.card, // exact term
      SearchResultType.card, // prefix term
      SearchResultType.deck, // prefix name
    ]);
  });

  test('a contained match ranks below a prefix match', () async {
    await database.flashcardDao.insertFlashcard(
      'c_snap',
      'root',
      'snapp',
      'snapp',
      'x',
      0,
      0,
    );
    final results = await run('app');
    // 'snapp' contains but does not prefix 'app', so it sorts last.
    expect(results.last.id, 'c_snap');
  });

  test('hidden and deleted cards are excluded', () async {
    await database.flashcardDao.insertFlashcard(
      'c_hidden',
      'root',
      'appx',
      'appx',
      'x',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c_deleted',
      'root',
      'appy',
      'appy',
      'y',
      0,
      0,
    );
    await database.customStatement(
      "UPDATE flashcards SET is_hidden = 1 WHERE id = 'c_hidden'",
    );
    await database.customStatement(
      "UPDATE flashcards SET deleted_at = 1 WHERE id = 'c_deleted'",
    );

    final ids = (await run('app')).map((r) => r.id).toSet();
    expect(ids, isNot(contains('c_hidden')));
    expect(ids, isNot(contains('c_deleted')));
  });

  test('results never cross the language pair', () async {
    await database.deckDao.insertDeck(
      'other',
      'lp2',
      null,
      'Apps',
      'apps',
      0,
      0,
    );
    final ids = (await run('app')).map((r) => r.id).toSet();
    expect(ids, isNot(contains('other')));
  });
}
