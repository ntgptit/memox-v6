import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';

/// WBS 6.1 — countSubtreeDecks reports the nested-deck count for the
/// delete/reset impact summary: all descendants, excluding the deck itself
/// (delete-deck.md §4).
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
    // root ─┬─ child1 ─── grandchild
    //       └─ child2
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Root',
      'root',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'child1',
      'lp1',
      'root',
      'Child 1',
      'child 1',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'child2',
      'lp1',
      'root',
      'Child 2',
      'child 2',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'grandchild',
      'lp1',
      'child1',
      'Grandchild',
      'grandchild',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('the root counts every descendant, not itself', () async {
    expect(await decks.countSubtreeDecks('root'), 3);
  });

  test('an intermediate parent counts only its own descendants', () async {
    expect(await decks.countSubtreeDecks('child1'), 1);
  });

  test('a leaf deck has no nested decks', () async {
    expect(await decks.countSubtreeDecks('child2'), 0);
    expect(await decks.countSubtreeDecks('grandchild'), 0);
  });

  // WBS 6.2 — ancestors returns the breadcrumb chain root → … → the deck.
  test('ancestors returns the chain ordered root first, deck last', () async {
    final chain = await decks.ancestors('grandchild');
    expect(chain.map((d) => d.id).toList(), ['root', 'child1', 'grandchild']);
  });

  test('a root deck is its own single-element chain', () async {
    final chain = await decks.ancestors('root');
    expect(chain.map((d) => d.id).toList(), ['root']);
  });

  test('a missing deck has an empty chain', () async {
    expect(await decks.ancestors('nope'), isEmpty);
  });
}
