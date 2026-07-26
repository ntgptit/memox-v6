import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/guess_question_builder.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';

/// WBS 5.7.4 — the first-learning release journey, end to end over the real
/// store: five valid cards, a newLearning session through all five stages,
/// finalize, and the Today projection that follows.
///
/// The five-stage pipeline already had a test against a fake repository. What
/// nothing covered is the seam this crosses: what the **dashboard** says once
/// a first session is done. Every Today defect this session found lived in
/// exactly that gap — the study half was right and the projection disagreed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late DriftLearningProgressRepository progress;
  late DriftDeckRepository decks;
  late StartStudySessionUseCase start;
  late AnswerStudyStageUseCase answer;
  late LoadStudyRuntimeUseCase loadRuntime;
  late FinalizeStudySessionUseCase finalize;
  late LoadTodayProjectionUseCase loadToday;

  final now = DateTime.utc(2026, 7, 27, 9);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    progress = DriftLearningProgressRepository(database);
    decks = DriftDeckRepository(database, _FixedClock(now));
    const clock = _FixedClock.new;
    start = StartStudySessionUseCase(
      progress: progress,
      cards: DriftFlashcardRepository(database),
      sessions: sessions,
      clock: clock(now),
      idGenerator: _SeqIds('start'),
    );
    answer = AnswerStudyStageUseCase(
      sessions: sessions,
      factory: StudyModeFactory.standard(),
      clock: clock(now),
      idGenerator: _SeqIds('answer'),
    );
    loadRuntime = LoadStudyRuntimeUseCase(sessions: sessions);
    finalize = FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: clock(now),
      idGenerator: _SeqIds('final'),
    );
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
        clock: clock(now),
      ),
    );
  });

  tearDown(() => database.close());

  /// A fresh install that has just completed first-run: one pair, one deck,
  /// five cards with distinct meanings — the minimum a newLearning session
  /// needs for its Guess stage.
  Future<void> freshInstallWithFiveCards() async {
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Greetings',
      'greetings',
      0,
      0,
    );
    for (final (id, term, meaning) in const <(String, String, String)>[
      ('c1', 'hello', 'xin chào'),
      ('c2', 'goodbye', 'tạm biệt'),
      ('c3', 'please', 'làm ơn'),
      ('c4', 'thanks', 'cảm ơn'),
      ('c5', 'sorry', 'xin lỗi'),
    ]) {
      await database.flashcardDao.insertFlashcard(
        id,
        'd1',
        term,
        term,
        meaning,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        0,
        0,
      );
    }
  }

  StudyModeInput passingInput(StudyRuntimeState state) {
    final card = state.currentCard!;
    final round = state.position.roundIndex;
    final sessionId = state.session.id;
    final event =
        '${state.currentMode.id}-$round-${state.position.cardPosition}';
    switch (state.currentMode) {
      case StudyModeType.review:
        return ReviewInput(
          sessionId: sessionId,
          cardId: card.cardId,
          eventId: event,
        );
      case StudyModeType.match:
        return MatchInput(
          sessionId: sessionId,
          cardId: card.cardId,
          roundIndex: round,
          eventId: event,
          termPairId: card.cardId,
          selectedMeaningPairId: card.cardId,
          termMeaning: card.meaning,
          selectedMeaning: card.meaning,
        );
      case StudyModeType.guess:
        final question = const GuessQuestionBuilder().build(
          sessionId: sessionId,
          roundIndex: round,
          target: GuessCandidate(cardId: card.cardId, meaning: card.meaning),
          pool: <GuessCandidate>[
            for (final c in state.cardsById.values)
              GuessCandidate(cardId: c.cardId, meaning: c.meaning),
          ],
        );
        return GuessInput(
          sessionId: sessionId,
          cardId: card.cardId,
          roundIndex: round,
          eventId: event,
          options: question.options,
          correctChoiceId: question.correctChoiceId,
          selectedChoiceId: question.correctChoiceId,
        );
      case StudyModeType.recall:
        return RecallInput(
          sessionId: sessionId,
          cardId: card.cardId,
          roundIndex: round,
          eventId: event,
          revealed: true,
          resolution: RecallResolution.remembered,
          elapsedActiveMs: 1000,
        );
      case StudyModeType.fill:
        return FillInput(
          sessionId: sessionId,
          cardId: card.cardId,
          roundIndex: round,
          eventId: event,
          rawInput: card.term,
          acceptedAnswers: <String>[card.term],
        );
      case StudyModeType.srsBinaryReview:
        throw StateError('srsBinaryReview is not a newLearning stage');
    }
  }

  test('a first session leaves Today caught up, not empty', () async {
    await freshInstallWithFiveCards();

    // Before studying: five unstudied cards, nothing due. Caught-up is the
    // honest state only because that surface offers the new-learning action
    // when `newCount > 0` — without it this would be a congratulation shown
    // to someone who has never studied.
    final before = await loadToday();
    expect(before.primaryAction, TodayPrimaryAction.caughtUp);
    expect(before.newCount, 5);
    expect(before.dueCount, 0);

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.newLearning,
    );
    var runtime = (await loadRuntime())!;
    for (var step = 0; step < 200 && !runtime.isComplete; step++) {
      runtime = await answer.call(runtime, passingInput(runtime));
    }
    expect(runtime.isComplete, isTrue, reason: 'all five stages complete');

    final summary = await finalize.call(runtime);
    expect(summary.reviewedCount, 5);
    expect(summary.correctCount, 5);

    // Activation puts every card in Box 1 with a future due date
    // (`srs-8-box-policy.md` SRS8-001), so the library is no longer new and
    // nothing is due yet.
    for (final id in const <String>['c1', 'c2', 'c3', 'c4', 'c5']) {
      final card = await progress.findByCard(id);
      expect(card!.box, 1, reason: '$id activated');
      expect(card.dueAt, isNotNull);
    }

    final after = await loadToday();
    // The library has content and nothing is due — caught up, which is a
    // different state from the empty library it started as.
    expect(after.primaryAction, TodayPrimaryAction.caughtUp);
    expect(after.dueCount, 0);
    expect(after.newCount, 0, reason: 'no card is unstudied any more');
    expect(after.pausedSession, isNull, reason: 'the session finalized');
  });

  test('the activated cards come back due when their date arrives', () async {
    await freshInstallWithFiveCards();

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.newLearning,
    );
    var runtime = (await loadRuntime())!;
    for (var step = 0; step < 200 && !runtime.isComplete; step++) {
      runtime = await answer.call(runtime, passingInput(runtime));
    }
    await finalize.call(runtime);

    // A Today read taken after every due date has passed.
    final later = LoadTodayProjectionUseCase(
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
        clock: _FixedClock(now.add(const Duration(days: 30))),
      ),
    );

    final projection = await later();

    expect(projection.primaryAction, TodayPrimaryAction.startReview);
    expect(projection.dueCount, 5);
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
