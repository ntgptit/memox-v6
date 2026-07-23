import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';

/// WBS 6.2 — moveDestinations lists the decks a deck can be reparented under:
/// same language pair, excluding its own subtree (cycle), decks that hold
/// direct cards (4.3 mixed content) and its current parent (a no-op).
void main() {
  late db.AppDatabase database;
  late DriftDeckRepository decks;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, const SystemClock());
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
    // lp1:  root ─┬─ grammar ─── verbs (+card)
    //             └─ vocab (empty)
    //        work (empty root)
    // lp2:  other (empty root) — proves pair scoping.
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'grammar',
      'lp1',
      'root',
      'Grammar',
      'grammar',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'verbs',
      'lp1',
      'grammar',
      'Verbs',
      'verbs',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'vocab',
      'lp1',
      'root',
      'Vocab',
      'vocab',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'work',
      'lp1',
      null,
      'Work',
      'work',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'other',
      'lp2',
      null,
      'Other',
      'other',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      'verbs',
      't1',
      't1',
      'm1',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<List<String>> destinationIds(String movingDeckId) async {
    final rows = await decks.moveDestinations(
      'lp1',
      movingDeckId: movingDeckId,
    );
    return rows.map((d) => d.id).toList();
  }

  test('excludes the subtree, the current parent, and card decks', () async {
    // Moving grammar: subtree {grammar, verbs}, parent root, verbs holds a card.
    expect(await destinationIds('grammar'), ['vocab', 'work']);
  });

  test('a card-holding deck is never a destination', () async {
    // Moving vocab: verbs is excluded because it holds a card; root is the
    // current parent. Grammar (a childed but card-free deck) stays eligible.
    expect(await destinationIds('vocab'), ['grammar', 'work']);
  });

  test(
    'a root deck can descend into any card-free deck outside itself',
    () async {
      // Moving root: subtree {root, grammar, verbs, vocab}; only work survives.
      expect(await destinationIds('root'), ['work']);
    },
  );

  test('destinations never cross the language pair', () async {
    expect(await destinationIds('grammar'), isNot(contains('other')));
  });
}
