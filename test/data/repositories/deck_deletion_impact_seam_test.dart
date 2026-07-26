import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/domain/usecases/deck/delete_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';

/// WBS 6.1 — the delete confirm's impact summary against what delete removes
/// (`delete-deck.md` §1: the copy names the child decks, cards and learning
/// progress that go).
///
/// A confirm dialog is only worth showing if its numbers are the ones the
/// action will act on. Both halves existed and were tested separately; this
/// runs the summary and the delete over one store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftDeckRepository decks;
  late LoadDeckDeletionImpactUseCase impact;

  final now = DateTime.utc(2026, 7, 27, 9);

  Future<void> deck(String id, {String? parentId}) =>
      database.deckDao.insertDeck(id, 'lp1', parentId, id, id, 0, 0);

  Future<void> card(String id, String deckId, {int box = 0}) async {
    await database.flashcardDao.insertFlashcard(id, deckId, id, id, id, 0, 0);
    await database.learningProgressDao.insertProgress(
      'p-$id',
      id,
      box,
      box >= 1 && box <= 7 ? now.millisecondsSinceEpoch : null,
      0,
      0,
    );
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, _FixedClock(now));
    impact = LoadDeckDeletionImpactUseCase(decks: decks);
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
  });

  tearDown(() => database.close());

  test('the summary counts the whole subtree the delete removes', () async {
    // Deck exclusivity (WBS 4.3): a deck holds cards or subdecks, never
    // both — the schema refuses the mix, so the cards live in the leaves.
    await deck('root');
    await deck('child', parentId: 'root');
    await deck('sibling', parentId: 'root');
    await card('c1', 'sibling');
    await card('c2', 'child');
    await card('c3', 'child');

    final summary = await impact('root');
    expect(summary.deckCount, 2, reason: 'descendants exclude the deck itself');
    expect(summary.cardCount, 3);

    await DeleteDeckUseCase(decks: decks).call('root');

    // Everything the summary named is gone.
    final remaining = await database
        .customSelect('SELECT COUNT(*) AS c FROM flashcards')
        .getSingle();
    expect(remaining.data['c'], 0);
    expect(await decks.findById('child'), isNull);
  });

  // §1 asks the copy to name the learning progress removed. Counting progress
  // rows would restate the card count — every card has one from creation — so
  // what is counted is cards past Box 0, which is where history begins.
  test('learning progress is counted as cards with history', () async {
    await deck('root');
    await card('new1', 'root');
    await card('new2', 'root');
    await card('studied1', 'root', box: 2);
    await card('mastered', 'root', box: 8);

    final summary = await impact('root');

    expect(summary.cardCount, 4);
    expect(
      summary.studiedCardCount,
      2,
      reason: 'Box 2 and Box 8 carry history; Box 0 does not',
    );
  });

  test('a deck nobody has studied reports no progress lost', () async {
    await deck('root');
    await card('c1', 'root');

    final summary = await impact('root');

    expect(summary.cardCount, 1);
    expect(summary.studiedCardCount, 0);
  });

  test('a soft-deleted card is in neither count', () async {
    await deck('root');
    await card('c1', 'root', box: 3);
    await card('gone', 'root', box: 3);
    await database.customStatement(
      'UPDATE flashcards SET deleted_at = ? WHERE id = ?',
      <Object?>[now.millisecondsSinceEpoch, 'gone'],
    );

    final summary = await impact('root');

    expect(summary.cardCount, 1);
    expect(summary.studiedCardCount, 1);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}
