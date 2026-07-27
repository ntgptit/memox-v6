import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/move_destination.dart';

/// `move-deck.md` §3 node E, §4 and §11 — an ineligible destination is shown
/// disabled with its reason, not hidden.
///
/// The picker filtered them out in SQL, so a deck that holds cards and a deck
/// that was never there looked the same: absent.
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
    // root
    //  ├── moving       (the deck being moved)
    //  │    └── inside  (its descendant)
    //  ├── leaf         (holds a card)
    //  └── empty        (a valid target)
    for (final (id, parent) in const <(String, String?)>[
      ('root', null),
      ('moving', 'root'),
      ('inside', 'moving'),
      ('leaf', null),
      ('empty', null),
    ]) {
      await database.deckDao.insertDeck(id, 'lp1', parent, id, id, 0, 0);
    }
    await database.flashcardDao.insertFlashcard(
      'c1',
      'leaf',
      'term',
      'term',
      'meaning',
      0,
      0,
    );
  });

  Future<Map<String, MoveIneligibility?>> reasons() async {
    final rows = await decks.moveDestinationCandidates(
      'lp1',
      movingDeckId: 'moving',
    );
    return <String, MoveIneligibility?>{
      for (final row in rows) row.deck.id: row.ineligibility,
    };
  }

  test('every deck in the pair is listed, eligible or not', () async {
    expect((await reasons()).keys.toSet(), <String>{
      'root',
      'moving',
      'inside',
      'leaf',
      'empty',
    });
  });

  test('each blocked deck carries the reason it is blocked', () async {
    final byId = await reasons();
    expect(byId['moving'], MoveIneligibility.self);
    expect(byId['inside'], MoveIneligibility.descendant);
    expect(byId['leaf'], MoveIneligibility.holdsCards);
    expect(byId['root'], MoveIneligibility.alreadyThere);
  });

  test('a valid target carries no reason', () async {
    expect((await reasons())['empty'], isNull);
  });

  // The list is a picker, not the authority: §12 leaves the store the final
  // say, and the eligible set here must still match what it will accept.
  test('the eligible rows are exactly the old destination list', () async {
    final eligible = (await decks.moveDestinationCandidates(
      'lp1',
      movingDeckId: 'moving',
    )).where((row) => row.isEligible).map((row) => row.deck.id).toList();
    final legacy = (await decks.moveDestinations(
      'lp1',
      movingDeckId: 'moving',
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
