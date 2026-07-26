import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/deck/move_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/delete_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/move_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';

/// WBS 5.7.1 — the structural library mutations reach the dashboard.
///
/// `int-25` was two halves of one shape: a mutation tested only against a fake
/// repository, whose real store could not perform it. These are the remaining
/// mutations of that family — move a deck, move a card, delete a card — driven
/// over the real store and then read through the projection.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;
  late DriftDeckRepository decks;
  late DriftFlashcardRepository cards;
  late LoadTodayProjectionUseCase loadToday;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    progress = DriftLearningProgressRepository(database);
    decks = DriftDeckRepository(database, _FixedClock(now));
    cards = DriftFlashcardRepository(database);
    loadToday = LoadTodayProjectionUseCase(
      sessions: DriftStudySessionRepository(database),
      decks: decks,
      languagePairs: _StubPairs(
        LanguagePair(
          id: 'lp1',
          learningLanguageCode: 'en',
          nativeLanguageCode: 'vi',
          normalizedPairKey: 'en|vi',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      queueCounts: LoadStudyQueueCountsUseCase(
        progress: progress,
        decks: decks,
        clock: _FixedClock(now),
      ),
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

  Future<void> deck(
    String id,
    String name, {
    String? parentId,
    int cardCount = 2,
  }) async {
    await database.deckDao.insertDeck(
      id,
      'lp1',
      parentId,
      name,
      name.toLowerCase(),
      0,
      0,
    );
    for (var index = 0; index < cardCount; index++) {
      final cardId = '$id-c$index';
      await database.flashcardDao.insertFlashcard(
        cardId,
        id,
        cardId,
        cardId,
        'meaning-$cardId',
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$cardId',
        cardId,
        3,
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  }

  // The library total is the pair's, so nesting a deck must not change it —
  // and the deck must stop being its own Recent-decks row, because that list
  // is roots only.
  test('moving a deck under another keeps its cards in the total', () async {
    await deck('parent', 'Parent', cardCount: 0);
    await deck('child', 'Child');

    final before = await loadToday();
    expect(before.dueCount, 2);
    expect(before.recentDecks, hasLength(2));

    await MoveDeckUseCase(
      decks: decks,
      clock: _FixedClock(now),
    ).call(deckId: 'child', newParentId: 'parent');

    final after = await loadToday();
    expect(after.dueCount, 2, reason: 'the pair still holds the same cards');
    expect(
      after.recentDecks.map((row) => row.deck.id).toList(),
      <String>['parent'],
      reason: 'Recent decks lists roots; the child is inside one now',
    );
  });

  // The counters the Recent-decks rows show are direct cards only, so a card
  // moving between decks has to move between rows.
  test('moving a card moves its counts to the new deck', () async {
    await deck('d1', 'Alpha');
    await deck('d2', 'Zulu', cardCount: 0);

    await MoveFlashcardUseCase(
      cards: cards,
      decks: decks,
      clock: _FixedClock(now),
    ).call(cardId: 'd1-c0', targetDeckId: 'd2');

    final after = await loadToday();
    final byId = <String, int>{
      for (final row in after.recentDecks) row.deck.id: row.dueCount,
    };
    expect(byId['d1'], 1);
    expect(byId['d2'], 1);
    expect(after.dueCount, 2, reason: 'the library total is unchanged');
  });

  // Deleting a card is a soft delete, so nothing that references it breaks —
  // but it must leave every count the dashboard shows.
  test('deleting a card removes it from the counts', () async {
    await deck('d1', 'Alpha');

    await DeleteFlashcardUseCase(
      cards: cards,
      clock: _FixedClock(now),
    ).deleteCard('d1-c0');

    final after = await loadToday();
    expect(after.dueCount, 1);
    expect(after.libraryMastery.studiableCount, 1);
    expect(
      after.recentDecks.single.cardCount,
      1,
      reason: 'a deleted card is not one of the deck\'s cards any more',
    );
  });

  test(
    'deleting the last card leaves the deck but empties the queues',
    () async {
      await deck('d1', 'Alpha', cardCount: 1);

      await DeleteFlashcardUseCase(
        cards: cards,
        clock: _FixedClock(now),
      ).deleteCard('d1-c0');

      final after = await loadToday();
      expect(after.dueCount, 0);
      expect(
        after.primaryAction,
        TodayPrimaryAction.createLibrary,
        reason: 'a library with no cards is empty, however many decks remain',
      );
    },
  );
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _StubPairs implements SelectLanguagePairUseCase {
  _StubPairs(this._pair);
  final LanguagePair _pair;
  @override
  Future<LanguagePair?> activePair() async => _pair;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
