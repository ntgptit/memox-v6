import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/deck/delete_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/reset_deck_progress_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';

/// WBS 5.7.1 — library edits reach the dashboard
/// (`handle-empty-library-today.md` §1; `reset-deck-progress.md`;
/// `surface-due-cards.md` §1).
///
/// The projection composes counts from the library, and those counts move for
/// reasons that have nothing to do with studying: a deck is deleted, a deck's
/// progress is reset, a card is hidden. Each is owned by a different use case
/// and each was tested only on its own side.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;
  late DriftDeckRepository decks;
  late LoadTodayProjectionUseCase loadToday;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    progress = DriftLearningProgressRepository(database);
    decks = DriftDeckRepository(database, _FixedClock(now));
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
    int cards = 2,
    int box = 3,
  }) async {
    await database.deckDao.insertDeck(
      id,
      'lp1',
      null,
      name,
      name.toLowerCase(),
      0,
      0,
    );
    for (var index = 0; index < cards; index++) {
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
        box,
        // Boxes 1..7 must carry a due date and boxes 0 and 8 must not
        // (`srs-8-box-policy.md`; the schema CHECKs it).
        box == 0 || box == 8 ? null : dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  }

  // `handle-empty-library-today.md` §1: "Deleted-last-content refresh về Empty
  // an toàn." The empty state is what tells a learner how to start again, so
  // getting stuck on caught-up would leave them with a congratulation and no
  // deck.
  test('deleting the last deck returns Today to the empty library', () async {
    await deck('d1', 'Alpha');

    final before = await loadToday();
    expect(before.primaryAction, TodayPrimaryAction.startReview);

    await DeleteDeckUseCase(decks: decks).call('d1');

    final after = await loadToday();
    expect(after.primaryAction, TodayPrimaryAction.createLibrary);
    expect(after.dueCount, 0);
    expect(after.recentDecks, isEmpty);
    expect(after.libraryMastery.studiableCount, 0);
  });

  test('deleting one of two decks leaves the other studiable', () async {
    await deck('d1', 'Alpha');
    await deck('d2', 'Zulu');

    await DeleteDeckUseCase(decks: decks).call('d1');

    final after = await loadToday();
    expect(after.primaryAction, TodayPrimaryAction.startReview);
    expect(after.dueCount, 2, reason: 'only the surviving deck counts');
    expect(after.recentDecks.single.deck.id, 'd2');
  });

  // Reset returns every card to Box 0, so the library becomes new rather than
  // due — and the mastery stat has to fall with it.
  test('resetting a deck moves its cards from due to new', () async {
    await deck('d1', 'Alpha', cards: 2, box: 8);

    final before = await loadToday();
    expect(before.libraryMastery.masteredCount, 2);

    await ResetDeckProgressUseCase(
      progress: progress,
      idGenerator: _SeqIds('reset'),
      clock: _FixedClock(now),
    ).call('d1');

    final after = await loadToday();
    expect(after.libraryMastery.masteredCount, 0);
    expect(after.dueCount, 0);
    expect(after.newCount, 2, reason: 'Box 0 is the new queue');
    expect(
      after.primaryAction,
      TodayPrimaryAction.caughtUp,
      reason: 'new cards are not due; the caught-up state offers to learn them',
    );
  });

  // `surface-due-cards.md` §1 excludes hidden cards from the queues, and the
  // mastery denominator excludes them too — a hidden card can never reach
  // Box 8, so counting it would put 100% out of reach.
  test(
    'hiding a card removes it from both the queue and the denominator',
    () async {
      await deck('d1', 'Alpha', cards: 2);

      final before = await loadToday();
      expect(before.dueCount, 2);
      expect(before.libraryMastery.studiableCount, 2);

      await database.customStatement(
        'UPDATE flashcards SET is_hidden = 1 WHERE id = ?',
        <Object?>['d1-c0'],
      );

      final after = await loadToday();
      expect(after.dueCount, 1);
      expect(after.libraryMastery.studiableCount, 1);
      expect(
        after.recentDecks.single.cardCount,
        2,
        reason: 'the deck still holds both; only the studiable set shrank',
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

class _SeqIds implements IdGenerator {
  _SeqIds(this._prefix);
  final String _prefix;
  int _n = 0;
  @override
  String newId() => '$_prefix-${_n++}';
}
