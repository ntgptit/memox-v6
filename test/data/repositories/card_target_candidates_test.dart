import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/domain/deck/card_target.dart';

/// `add-content-to-deck.md` §3 node F and §4 — a Parent is shown disabled with
/// its reason, not hidden.
///
/// The picker filtered Parents out in SQL, so a learner could not tell a deck
/// they must drill into from one that is not there. The same defect `int-89`
/// fixed for the deck-move picker, one flow over.
void main() {
  late db.AppDatabase database;
  late DriftDeckRepository decks;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    decks = DriftDeckRepository(database, _FixedClock(DateTime.utc(2026, 7)));

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    // parent ── child (the card's home)
    // empty                      (a valid target)
    for (final (id, parentId) in const <(String, String?)>[
      ('parent', null),
      ('child', 'parent'),
      ('empty', null),
    ]) {
      await database.deckDao.insertDeck(id, 'lp1', parentId, id, id, 0, 0);
    }
    await database.flashcardDao.insertFlashcard(
      'c1',
      'child',
      'term',
      'term',
      'meaning',
      0,
      0,
    );
  });

  Future<Map<String, CardTargetIneligibility?>> reasons() async {
    final rows = await decks.cardTargetCandidates('lp1', sourceDeckId: 'child');
    return <String, CardTargetIneligibility?>{
      for (final row in rows) row.deck.id: row.ineligibility,
    };
  }

  test('every deck in the pair is listed, eligible or not', () async {
    expect((await reasons()).keys.toSet(), <String>{
      'parent',
      'child',
      'empty',
    });
  });

  test('a Parent carries the reason it cannot take a card', () async {
    expect((await reasons())['parent'], CardTargetIneligibility.isParent);
  });

  test('the card\'s own deck is marked rather than dropped', () async {
    expect((await reasons())['child'], CardTargetIneligibility.sourceDeck);
  });

  test('an Empty deck is a valid target', () async {
    expect((await reasons())['empty'], isNull);
  });

  // The picker is not the authority: the eligible subset must keep matching
  // what the old query offered, or a shown row would fail on write.
  test('the eligible rows are exactly the old target list', () async {
    final eligible = (await decks.cardTargetCandidates(
      'lp1',
      sourceDeckId: 'child',
    )).where((row) => row.isEligible).map((row) => row.deck.id).toList();
    final legacy = (await decks.cardMoveTargets(
      'lp1',
      excludeDeckId: 'child',
    )).map((deck) => deck.id).toList();
    expect(eligible, legacy);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}
