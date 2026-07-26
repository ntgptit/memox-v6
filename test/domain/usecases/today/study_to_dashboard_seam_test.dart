import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';

/// WBS 5.7.1/5.7.2 — the dashboard's supporting sections read what studying
/// actually wrote.
///
/// The Recent-decks order and the mastery stat were tested against rows a
/// test had seeded by hand. That proves the queries, not that anything ever
/// produces those rows: a deck list ordered by `last_reviewed_at` is a silent
/// no-op if no study path ever sets it. This drives real sessions and then
/// asks the projection.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late DriftLearningProgressRepository progress;
  late DriftDeckRepository decks;
  late StartStudySessionUseCase start;
  late AnswerStudyStageUseCase answer;
  late LoadStudyRuntimeUseCase loadRuntime;
  late LoadTodayProjectionUseCase loadToday;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    progress = DriftLearningProgressRepository(database);
    decks = DriftDeckRepository(database, _FixedClock(now));
    start = StartStudySessionUseCase(
      progress: progress,
      cards: DriftFlashcardRepository(database),
      sessions: sessions,
      clock: _FixedClock(now),
      idGenerator: _SeqIds('start'),
    );
    answer = AnswerStudyStageUseCase(
      sessions: sessions,
      factory: StudyModeFactory.standard(),
      clock: _FixedClock(now),
      idGenerator: _SeqIds('answer'),
    );
    loadRuntime = LoadStudyRuntimeUseCase(sessions: sessions);
    loadToday = LoadTodayProjectionUseCase(
      sessions: sessions,
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

  /// A root deck holding [cards] due cards at [box].
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
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  }

  Future<void> studyDeck(String deckId, {int? finalizeAt}) async {
    await start.call(
      deckId: deckId,
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    var runtime = (await loadRuntime())!;
    for (var step = 0; step < 30 && !runtime.isComplete; step++) {
      final cardId = runtime.position.currentCardId!;
      runtime = await answer.call(
        runtime,
        SrsBinaryReviewInput(
          sessionId: runtime.session.id,
          cardId: cardId,
          roundIndex: runtime.position.roundIndex,
          eventId: 'srs-$cardId-r${runtime.position.roundIndex}',
          action: SrsBinaryAction.remembered,
        ),
      );
    }
    await FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: _FixedClock(
        finalizeAt == null ? now : now.add(Duration(milliseconds: finalizeAt)),
      ),
      idGenerator: _SeqIds('final-$deckId'),
    ).call(runtime);
  }

  // The Recent-decks order reads `last_reviewed_at`. Nothing proved a study
  // path ever writes it — an ordering nobody produces is a section that never
  // reorders, which looks exactly like one that works.
  test('studying a deck moves it to the front of Recent decks', () async {
    await deck('d1', 'Alpha');
    await deck('d2', 'Zulu');

    // Alphabetical while neither has been studied.
    final before = await loadToday();
    expect(before.recentDecks.map((row) => row.deck.id).toList(), <String>[
      'd1',
      'd2',
    ]);

    await studyDeck('d2');

    final after = await loadToday();
    expect(
      after.recentDecks.first.deck.id,
      'd2',
      reason: 'the deck just studied is the most recent one',
    );
  });

  test('the most recently studied deck leads, not the last created', () async {
    await deck('d1', 'Alpha');
    await deck('d2', 'Zulu');

    await studyDeck('d2');
    await studyDeck('d1', finalizeAt: 60000);

    final projection = await loadToday();
    expect(projection.recentDecks.map((row) => row.deck.id).toList(), <String>[
      'd1',
      'd2',
    ]);
  });

  // Box 8 is the mastered box, and it is reached by promotion through the
  // boxes — so a deck studied from Box 7 raises the library stat the strip
  // shows.
  test('a card promoted out of Box 7 raises the library mastery', () async {
    await deck('d1', 'Alpha', cards: 2, box: 7);

    final before = await loadToday();
    expect(before.libraryMastery.masteredCount, 0);
    expect(before.libraryMastery.studiableCount, 2);

    await studyDeck('d1');

    final after = await loadToday();
    expect(after.libraryMastery.masteredCount, 2);
    expect(after.libraryMastery.fraction, 1.0);
  });

  // `load-today-dashboard.md` §2: a resumable session outranks everything.
  test('a session left mid-way makes Today offer Continue', () async {
    await deck('d1', 'Alpha', cards: 3);

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    var runtime = (await loadRuntime())!;
    final cardId = runtime.position.currentCardId!;
    runtime = await answer.call(
      runtime,
      SrsBinaryReviewInput(
        sessionId: runtime.session.id,
        cardId: cardId,
        roundIndex: runtime.position.roundIndex,
        eventId: 'srs-$cardId-r1',
        action: SrsBinaryAction.remembered,
      ),
    );

    final projection = await loadToday();

    expect(projection.primaryAction, TodayPrimaryAction.continueSession);
    expect(projection.pausedSession, isNotNull);
    expect(
      projection.dueCount,
      3,
      reason: 'answers are graded at finalize, so nothing is due-cleared yet',
    );
  });
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
