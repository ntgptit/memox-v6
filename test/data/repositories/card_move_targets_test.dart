import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';

/// WBS 6.5 — cardMoveTargets lists the decks a card can move into: Empty or Leaf
/// decks (no child decks) in the pair, excluding the card's current deck
/// (move-flashcard.md §5). A Parent deck is never a target.
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
    // lp1:  parent ─── child (leaf, empty)
    //       source (the card's current deck)
    //       target (empty)
    // lp2:  other (empty) — proves pair scoping.
    await database.deckDao.insertDeck(
      'parent',
      'lp1',
      null,
      'Parent',
      'parent',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'child',
      'lp1',
      'parent',
      'Child',
      'child',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'source',
      'lp1',
      null,
      'Source',
      'source',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'target',
      'lp1',
      null,
      'Target',
      'target',
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
  });

  tearDown(() async {
    await database.close();
  });

  Future<List<String>> targetIds(String sourceDeckId) async {
    final rows = await decks.cardMoveTargets(
      'lp1',
      excludeDeckId: sourceDeckId,
    );
    return rows.map((d) => d.id).toList();
  }

  test('lists Empty/Leaf decks, excludes the Parent and the source', () async {
    // parent has a child -> Parent -> excluded; source excluded; child/target
    // are card-holding-eligible.
    expect(await targetIds('source'), ['child', 'target']);
  });

  test('the source deck is never its own target', () async {
    expect(await targetIds('target'), isNot(contains('target')));
    expect(await targetIds('target'), ['child', 'source']);
  });

  test('targets never cross the language pair', () async {
    expect(await targetIds('source'), isNot(contains('other')));
  });
}
