import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';

/// ST-TYPE-003 — a Practice session draws its queue from the scope.
///
/// The eligibility policy and the plan resolver both had full Practice arms,
/// and `StartStudySessionUseCase._cardIdsFor` had none, so nothing could ever
/// create one: every attempt threw `unsupported-session-type` (`int-79`).
///
/// Practice is the one type whose queue is the scope rather than a schedule —
/// it sets `scheduleSrs = false` and contributes no Goal or Streak, so a
/// card's box does not decide whether it can be practised.
void main() {
  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    progress = DriftLearningProgressRepository(database);

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'Deck', 'deck', 0, 0);
    await database.deckDao.insertDeck(
      'd2',
      'lp1',
      'd1',
      'Child',
      'child',
      0,
      0,
    );
  });

  Future<void> card(
    String id,
    String deck, {
    required int box,
    int? dueAt,
    bool hidden = false,
    bool deleted = false,
  }) async {
    await database.flashcardDao.insertFlashcard(
      id,
      deck,
      'term-$id',
      'term-$id',
      'meaning-$id',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p-$id',
      id,
      box,
      dueAt,
      0,
      0,
    );
    if (hidden) await database.flashcardDao.setFlashcardHidden(1, 0, id);
    if (deleted) await database.flashcardDao.softDeleteFlashcard(1, 0, id);
  }

  test('the scope is every studiable card, whatever its box', () async {
    await card('new', 'd2', box: 0);
    await card('due', 'd2', box: 3, dueAt: 0);
    // Neither new nor due: scheduled far ahead, and mastered.
    await card('later', 'd2', box: 4, dueAt: 9999999999999);
    await card('mastered', 'd2', box: 8);

    final ids = await progress.studiableCardIdsInScope(scopeDeckId: 'd1');

    expect(ids, <String>['due', 'later', 'mastered', 'new']);
  });

  test('hidden and deleted cards are not studiable', () async {
    await card('kept', 'd2', box: 0);
    await card('hidden', 'd2', box: 0, hidden: true);
    await card('gone', 'd2', box: 0, deleted: true);

    final ids = await progress.studiableCardIdsInScope(scopeDeckId: 'd1');

    expect(ids, <String>['kept']);
  });

  test('a scope with nothing in it yields nothing', () async {
    final ids = await progress.studiableCardIdsInScope(scopeDeckId: 'd3');
    expect(ids, isEmpty);
  });

  // The types that select from a schedule must keep doing so; Practice is an
  // addition, not a change to them.
  test('the scheduled types still read their own queues', () async {
    await card('new', 'd2', box: 0);
    await card('later', 'd2', box: 4, dueAt: 9999999999999);

    final candidates = await progress.studyCandidatesInScope(
      scopeDeckId: 'd1',
      nowUtc: DateTime.utc(2026, 7, 27),
    );

    expect(candidates.newCardIds, <String>['new']);
    expect(candidates.dueCardIds, isEmpty, reason: 'not due yet');
    expect(
      await progress.studiableCardIdsInScope(scopeDeckId: 'd1'),
      <String>['later', 'new'],
      reason: 'practice takes both',
    );
  });
}
