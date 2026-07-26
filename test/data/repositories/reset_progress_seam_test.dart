import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/reset_deck_progress_usecase.dart';

/// WBS 6.1 — the reset confirm's affected count against what the reset changes
/// (`reset-deck-progress.md` §5: the count is "cards có progress cần reset").
///
/// The sibling of the delete-impact seam. Both dialogs read one summary, and
/// the two counts on it mean different things: delete removes every card,
/// reset only touches the ones that left Box 0. Naming the wrong one promises
/// to undo work that was never done, and it is invisible from either side
/// alone — the summary is right, the reset is right, only the pairing is not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftDeckRepository decks;
  late DriftLearningProgressRepository progress;
  late LoadDeckDeletionImpactUseCase impact;
  late ResetDeckProgressUseCase reset;

  final now = DateTime.utc(2026, 7, 27, 9);

  Future<void> deck(String id, {String? parentId}) =>
      database.deckDao.insertDeck(id, 'lp1', parentId, id, id, 0, 0);

  /// Box 0 with no due date is the initial unlearned state
  /// (`srs-8-box-policy.md`); Boxes 1-7 carry a due date, Box 8 is mastered
  /// and carries none.
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

  Future<List<int>> boxes() async {
    final rows = await database
        .customSelect('SELECT box FROM learning_progress ORDER BY card_id')
        .get();
    return rows.map((row) => row.read<int>('box')).toList();
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, _FixedClock(now));
    progress = DriftLearningProgressRepository(database);
    impact = LoadDeckDeletionImpactUseCase(decks: decks);
    reset = ResetDeckProgressUseCase(
      progress: progress,
      idGenerator: _SeqIds('lp'),
      clock: _FixedClock(now),
    );
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

  test('the affected count is the cards the reset returns to Box 0', () async {
    await deck('root');
    await card('new1', 'root');
    await card('new2', 'root');
    await card('learning', 'root', box: 2);
    await card('nearly', 'root', box: 7);
    await card('mastered', 'root', box: 8);

    final before = await impact('root');
    expect(before.cardCount, 5);
    expect(
      before.studiedCardCount,
      3,
      reason: 'the two never-introduced cards have nothing to reset',
    );

    await reset('root');

    expect(await boxes(), everyElement(0));
    // What the dialog would say if reopened: nothing left to reset, and the
    // cards themselves untouched (§6 changes scheduling, never content).
    final after = await impact('root');
    expect(after.studiedCardCount, 0);
    expect(after.cardCount, 5);
  });

  test('a deck nobody has studied has nothing to reset', () async {
    await deck('root');
    await card('c1', 'root');
    await card('c2', 'root');

    final summary = await impact('root');

    expect(summary.cardCount, 2, reason: 'the cards are there');
    expect(
      summary.studiedCardCount,
      0,
      reason: 'so the confirm shows the nothing-to-reset state, not "2 cards"',
    );
  });

  // §7: the due/new summaries refresh after a reset. Box 8 is the case a
  // due-only reading would miss — a mastered card has no due date, so it sits
  // in neither queue until the reset puts it back in the new one.
  test('reset moves the scope out of the due queue and into new', () async {
    await deck('root');
    await card('due1', 'root', box: 3);
    await card('mastered', 'root', box: 8);

    final before = await progress.studyCandidatesInScope(
      scopeDeckId: 'root',
      nowUtc: now,
    );
    expect(before.dueCount, 1);
    expect(before.newCount, 0);

    await reset('root');

    final after = await progress.studyCandidatesInScope(
      scopeDeckId: 'root',
      nowUtc: now,
    );
    expect(after.dueCount, 0);
    expect(after.newCount, 2);
  });

  test('a parent reset reaches its descendants and leaves them there', () async {
    // Deck exclusivity (WBS 4.3): a deck holds cards or subdecks, never both.
    await deck('root');
    await deck('child', parentId: 'root');
    await card('c1', 'child', box: 4);
    await card('c2', 'child', box: 6);

    expect((await impact('root')).studiedCardCount, 2);

    await reset('root');

    expect(await boxes(), everyElement(0));
    expect(await decks.findById('child'), isNotNull, reason: 'hierarchy stays');
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  _SeqIds(this._prefix);
  final String _prefix;
  int _n = 0;
  @override
  String newId() => '$_prefix-${_n++}';
}
