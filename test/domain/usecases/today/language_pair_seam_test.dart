import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/language_pair/remove_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';

/// WBS 5.7.1 — the dashboard follows the active language pair.
///
/// Every count Today shows is pair-scoped, and the pair comes from a stored
/// preference rather than from anything the projection holds. This is the
/// last source feeding it that had never been driven across the boundary —
/// and its scoping has a history: Today once counted due cards from every
/// pair, advertising review work from a library the learner could not see.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;
  late DriftDeckRepository decks;
  late DriftPreferenceRepository preferences;
  late SelectLanguagePairUseCase select;
  late LoadTodayProjectionUseCase loadToday;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    progress = DriftLearningProgressRepository(database);
    decks = DriftDeckRepository(database, _FixedClock(now));
    preferences = DriftPreferenceRepository(database);
    select = SelectLanguagePairUseCase(
      pairs: DriftLanguagePairRepository(database),
      preferences: preferences,
      clock: _FixedClock(now),
    );
    loadToday = LoadTodayProjectionUseCase(
      sessions: DriftStudySessionRepository(database),
      decks: decks,
      languagePairs: select,
      queueCounts: LoadStudyQueueCountsUseCase(
        progress: progress,
        decks: decks,
        clock: _FixedClock(now),
      ),
    );
  });

  tearDown(() => database.close());

  Future<void> pair(String id, String learning) async {
    await database.languagePairDao.insertLanguagePair(
      id,
      learning,
      'vi',
      '$learning|vi',
      0,
      0,
    );
  }

  Future<void> deck(String id, String pairId, {int cards = 2}) async {
    await database.deckDao.insertDeck(id, pairId, null, id, id, 0, 0);
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
        3,
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  }

  // Every number on the dashboard belongs to one pair. Today once read an
  // unscoped due count and advertised review work from a library the Library
  // tab does not even show.
  test('switching the active pair switches every count with it', () async {
    await pair('lp1', 'en');
    await pair('lp2', 'ko');
    await deck('d1', 'lp1', cards: 2);
    await deck('d2', 'lp2', cards: 5);

    await select('lp1');
    final first = await loadToday();
    expect(first.dueCount, 2);
    expect(first.libraryMastery.studiableCount, 2);
    expect(first.recentDecks.single.deck.id, 'd1');

    await select('lp2');
    final second = await loadToday();
    expect(second.dueCount, 5);
    expect(second.libraryMastery.studiableCount, 5);
    expect(second.recentDecks.single.deck.id, 'd2');
  });

  // No selection is not an empty library, but the dashboard has nothing to
  // scope to either — and must not fall back to counting everything.
  test('with no pair selected nothing is counted', () async {
    await pair('lp1', 'en');
    await deck('d1', 'lp1', cards: 3);

    final projection = await loadToday();

    expect(projection.primaryAction, TodayPrimaryAction.createLibrary);
    expect(projection.dueCount, 0);
    expect(projection.recentDecks, isEmpty);
    expect(projection.libraryMastery.studiableCount, 0);
  });

  // `remove-language-pair.md`: a pair that still owns decks never deletes.
  test('a pair owning decks cannot be removed', () async {
    await pair('lp1', 'en');
    await deck('d1', 'lp1');
    await select('lp1');

    await expectLater(
      RemoveLanguagePairUseCase(
        pairs: DriftLanguagePairRepository(database),
        decks: decks,
        preferences: preferences,
      ).call('lp1'),
      throwsA(
        isA<ConflictFailure>().having((f) => f.code, 'code', 'deck-dependency'),
      ),
    );

    // The dashboard is untouched by the refused removal.
    final projection = await loadToday();
    expect(projection.dueCount, 2);
  });

  // Removing the active pair clears the stored selection, so the projection
  // must not keep reading through a dangling id.
  test('removing the active pair leaves Today with no selection', () async {
    await pair('lp1', 'en');
    await select('lp1');

    await RemoveLanguagePairUseCase(
      pairs: DriftLanguagePairRepository(database),
      decks: decks,
      preferences: preferences,
    ).call('lp1');

    final projection = await loadToday();
    expect(projection.primaryAction, TodayPrimaryAction.createLibrary);
    expect(projection.dueCount, 0);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}
