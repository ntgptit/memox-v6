import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_streak_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_goal_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/load_daily_progress_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/track_daily_goal_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_streak/record_streak_day_usecase.dart';

/// WBS 5.7.4 — what finalize writes is what Today reads back
/// (`track-daily-goal.md`; `record-streak-day.md`; `metrics-v1`).
///
/// Two use cases meet at the goal bucket and the streak day records: finalize
/// writes them, `LoadDailyProgressUseCase` reads them. The unit tests cover
/// each side against fakes. This runs both over one real store, which is the
/// only place a disagreement between writer and reader can show up — and
/// `int-11` was exactly such a disagreement, the reader dropping the streak
/// whenever no goal was configured.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late DriftLearningProgressRepository progress;
  late DriftStreakRepository streaks;
  late DriftStudyGoalRepository goals;
  late StartStudySessionUseCase start;
  late AnswerStudyStageUseCase answer;
  late LoadStudyRuntimeUseCase loadRuntime;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));
  const zone = FixedOffsetTimeZone(id: 'UTC', offset: Duration.zero);
  // `now` in UTC.
  const today = '2026-07-27';

  FinalizeStudySessionUseCase finalizeWith({required bool contributions}) {
    return FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: _FixedClock(now),
      idGenerator: _SeqIds('final'),
      recordStreakDay: contributions
          ? RecordStreakDayUseCase(
              streaks: streaks,
              timeZone: zone,
              idGenerator: _SeqIds('streak'),
            )
          : null,
      trackDailyGoal: contributions
          ? TrackDailyGoalUseCase(
              goals: goals,
              timeZone: zone,
              idGenerator: _SeqIds('goal'),
            )
          : null,
      streaks: contributions ? streaks : null,
      timeZone: contributions ? zone : null,
    );
  }

  LoadDailyProgressUseCase readToday() => LoadDailyProgressUseCase(
    streaks: streaks,
    goals: goals,
    timeZone: zone,
    clock: _FixedClock(now),
  );

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    progress = DriftLearningProgressRepository(database);
    streaks = DriftStreakRepository(database);
    goals = DriftStudyGoalRepository(database);
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

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
    for (final (id, meaning) in const <(String, String)>[
      ('c1', 'one'),
      ('c2', 'two'),
    ]) {
      await database.flashcardDao.insertFlashcard(
        id,
        'd1',
        id,
        id,
        meaning,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        3,
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  });

  tearDown(() => database.close());

  Future<void> configureGoal({required int target}) async {
    await database.studyGoalDao.insertGoal(
      'g1',
      1,
      target,
      today,
      zone.id,
      now.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch,
    );
  }

  Future<void> finishDueSession({required bool contributions}) async {
    await start.call(
      deckId: 'd1',
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
    await finalizeWith(contributions: contributions).call(runtime);
  }

  test('what finalize wrote is what Today reads', () async {
    await configureGoal(target: 5);

    await finishDueSession(contributions: true);
    final status = await readToday()();

    expect(status.goalDoneCards, 2, reason: 'both cards qualified');
    expect(status.goalTargetCards, 5);
    expect(status.streakDays, 1, reason: 'today is the first qualified day');
    expect(status.studiedToday, isTrue);
    expect(status.hasStreakHistory, isTrue);
    expect(status.isMet, isFalse);
  });

  // `int-11`: the reader returned `none()` the moment no goal existed, so a
  // learner mid-streak who had never set a target was shown a streak of zero.
  // The streak does not depend on the goal (`record-streak-day.md` §6).
  test('with no goal configured the streak still reads back', () async {
    await finishDueSession(contributions: true);
    final status = await readToday()();

    expect(status.hasGoal, isFalse);
    expect(status.streakDays, 1);
    expect(status.studiedToday, isTrue);
  });

  test('a met goal reads as met on both sides', () async {
    await configureGoal(target: 2);

    await finishDueSession(contributions: true);
    final status = await readToday()();

    expect(status.goalDoneCards, 2);
    expect(status.goalTargetCards, 2);
    expect(status.isMet, isTrue);
  });

  // `track-daily-goal.md` §1: "Paused/abandoned/retried Finalize không
  // double-count." The day bucket rides the finalize exactly-once contract, so
  // a retried finalize must not count the same cards twice.
  test('a retried finalize does not double-count the day', () async {
    await configureGoal(target: 10);

    await start.call(
      deckId: 'd1',
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
    final finalize = finalizeWith(contributions: true);
    await finalize.call(runtime);
    final afterFirst = await readToday()();

    await finalize.call(runtime);
    final afterSecond = await readToday()();

    expect(afterSecond.goalDoneCards, afterFirst.goalDoneCards);
    expect(afterSecond.streakDays, afterFirst.streakDays);
  });

  // A finalize wired without the optional contributors writes neither record,
  // and the read is honest about that rather than inventing a streak.
  test('a finalize without contributors leaves both empty', () async {
    await configureGoal(target: 5);

    await finishDueSession(contributions: false);
    final status = await readToday()();

    expect(status.goalDoneCards, 0);
    expect(status.streakDays, 0);
    expect(status.studiedToday, isFalse);
    expect(status.hasStreakHistory, isFalse);
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
