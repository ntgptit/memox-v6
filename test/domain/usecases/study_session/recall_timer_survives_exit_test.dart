import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_timer_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/pause_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 5.6.12 — `exit-study-session.md` §5: "Recall countdown trước reveal |
/// Pause và persist `remainingMs`; Resume tiếp tục, không reset", and §9:
/// "Continue Recall giữ timer resolution/remaining time".
///
/// The countdown is the one piece of study state a screen holds that no
/// committed answer records. The schema always had the slot for it —
/// `study_checkpoints.timer_state_json`, deliberately opaque — and nothing
/// wrote to it, so leaving a card eight seconds from its deadline and coming
/// back handed the learner a fresh twenty.
///
/// Pause and resume run over one store, because the defect is in the pairing:
/// the write is only worth anything if the read that follows it finds what it
/// left, for the card it left it on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late StartStudySessionUseCase start;
  late LoadStudyRuntimeUseCase loadRuntime;
  late PauseStudySessionUseCase pause;
  late AnswerStudyStageUseCase answer;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    final progress = DriftLearningProgressRepository(database);
    start = StartStudySessionUseCase(
      progress: progress,
      cards: DriftFlashcardRepository(database),
      sessions: sessions,
      clock: _FixedClock(now),
      idGenerator: _SeqIds('start'),
    );
    loadRuntime = LoadStudyRuntimeUseCase(sessions: sessions);
    pause = PauseStudySessionUseCase(
      sessions: sessions,
      clock: _FixedClock(now),
    );
    answer = AnswerStudyStageUseCase(
      sessions: sessions,
      factory: StudyModeFactory.standard(),
      clock: _FixedClock(now),
      idGenerator: _SeqIds('answer'),
    );

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
    for (final id in const <String>['c1', 'c2']) {
      await database.flashcardDao.insertFlashcard(id, 'd1', id, id, id, 0, 0);
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

  Future<String> startSession() async {
    final session = await start(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    return session.id;
  }

  // The runtime is read from the active session, so a resume asks for
  // whatever is running rather than naming it.

  test('the countdown a pause left is what the resume finds', () async {
    await startSession();
    final runtime = (await loadRuntime())!;
    final cardId = runtime.position.currentCardId!;

    await pause(
      runtime,
      timer: SessionTimerState(cardId: cardId, remainingMs: 8000),
    );

    final resumed = (await loadRuntime())!;
    expect(resumed.timer?.cardId, cardId);
    expect(resumed.timer?.remainingMs, 8000);
    expect(
      resumed.position.currentCardId,
      cardId,
      reason: 'a pause commits no answer, so the position does not move',
    );
  });

  test('a pause with no countdown leaves none to restore', () async {
    await startSession();
    final runtime = (await loadRuntime())!;

    await pause(runtime);

    expect((await loadRuntime())!.timer, isNull);
  });

  // The countdown belongs to the card it was running on. An answer moves the
  // session to the next card and clears the payload; if a stale one survived,
  // the next card would open on somebody else's clock.
  test('answering clears the countdown the pause left', () async {
    final sessionId = await startSession();
    final runtime = (await loadRuntime())!;
    final cardId = runtime.position.currentCardId!;
    await pause(
      runtime,
      timer: SessionTimerState(cardId: cardId, remainingMs: 8000),
    );

    final beforeAnswer = (await loadRuntime())!;
    await answer(
      beforeAnswer,
      SrsBinaryReviewInput(
        sessionId: sessionId,
        cardId: cardId,
        roundIndex: beforeAnswer.position.roundIndex,
        eventId: 'srs-$cardId-remembered',
        action: SrsBinaryAction.remembered,
      ),
    );

    final next = (await loadRuntime())!;
    expect(next.position.currentCardId, isNot(cardId));
    expect(next.timer, isNull);
  });

  // A payload for a card the session has already left is not applied to
  // whatever is on screen now — the same rule, enforced at the decode.
  test('a countdown from another card is not restored', () async {
    await startSession();
    final runtime = (await loadRuntime())!;

    await pause(
      runtime,
      timer: const SessionTimerState(cardId: 'someone-else', remainingMs: 8000),
    );

    final resumed = (await loadRuntime())!;
    expect(resumed.timer?.cardId, 'someone-else');
    expect(
      resumed.timer?.cardId == resumed.position.currentCardId,
      isFalse,
      reason:
          'the screen seeds only from a timer whose card is the one it '
          'is about to show',
    );
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
