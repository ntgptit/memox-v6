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
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 5.6 — the due-review loop composes end to end: start over the due
/// queue, answer every card through the real factory and advance policy, and
/// finalize (`srs-binary-review.md`; `answer-study-stage.md`).
///
/// The first-learning pipeline had this test and due review did not, which is
/// how its stage reached production with no screen behind it. This walks the
/// same path a learner walks from Today's `Start review`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late DriftLearningProgressRepository progress;
  late StartStudySessionUseCase start;
  late AnswerStudyStageUseCase answer;
  late LoadStudyRuntimeUseCase loadRuntime;
  late FinalizeStudySessionUseCase finalize;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  /// A card already in the SRS at [box] with a due date in the past, which is
  /// what puts it in the due queue.
  Future<void> dueCard(String id, String meaning, {int box = 3}) async {
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
      box,
      dueAt.millisecondsSinceEpoch,
      0,
      0,
    );
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    progress = DriftLearningProgressRepository(database);
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
    finalize = FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: _FixedClock(now),
      idGenerator: _SeqIds('final'),
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
  });

  tearDown(() => database.close());

  /// Answers the current card until the session completes, using [actionFor]
  /// to decide each grade. Bounded so a stalled advance fails loudly instead
  /// of hanging the suite.
  Future<StudyRuntimeState> answerAll(
    StudyRuntimeState from,
    SrsBinaryAction Function(String cardId) actionFor,
  ) async {
    var runtime = from;
    for (var step = 0; step < 50 && !runtime.isComplete; step++) {
      final cardId = runtime.position.currentCardId;
      if (cardId == null) break;
      final action = actionFor(cardId);
      runtime = await answer.call(
        runtime,
        SrsBinaryReviewInput(
          sessionId: runtime.session.id,
          cardId: cardId,
          roundIndex: runtime.position.roundIndex,
          eventId:
              'srs-binary-$cardId-${action.name}-r'
              '${runtime.position.roundIndex}',
          action: action,
        ),
      );
    }
    return runtime;
  }

  Future<StudyRuntimeState> startDueReview() async {
    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    final runtime = await loadRuntime();
    expect(runtime, isNotNull, reason: 'the started session must load back');
    return runtime!;
  }

  test('a due session runs the binary stage over the due queue', () async {
    await dueCard('c1', 'one');
    await dueCard('c2', 'two');

    final runtime = await startDueReview();

    expect(runtime.session.type, SessionType.dueReview);
    expect(runtime.stages, <StudyModeType>[StudyModeType.srsBinaryReview]);
    expect(runtime.position.roundCardIds.toSet(), <String>{'c1', 'c2'});
  });

  test('remembering every card completes and finalizes', () async {
    await dueCard('c1', 'one');
    await dueCard('c2', 'two');

    final completed = await answerAll(
      await startDueReview(),
      (_) => SrsBinaryAction.remembered,
    );
    expect(completed.isComplete, isTrue);

    final summary = await finalize.call(completed);

    expect(summary.reviewedCount, 2);
    final persisted = await sessions.findById(completed.session.id);
    expect(persisted!.state, SessionState.completed);
  });

  // §2: "Action `Relearn` tạo sticky wrong trong current session. Card phải
  // pass ở mastery retry round trước khi session hoàn tất, nhưng terminal
  // grade vẫn wrong." §4: "Wrong retry không mất lapse trong current session."
  test('a relearned card returns in a retry round and stays wrong', () async {
    await dueCard('c1', 'one');
    await dueCard('c2', 'two');

    final started = await startDueReview();
    // c1 is failed once, then passed on the retry; c2 passes first time.
    final failedOnce = <String>{};
    final completed = await answerAll(started, (cardId) {
      if (cardId != 'c1') return SrsBinaryAction.remembered;
      if (failedOnce.add(cardId)) return SrsBinaryAction.relearn;
      return SrsBinaryAction.remembered;
    });

    expect(
      completed.isComplete,
      isTrue,
      reason: 'the failed card must be offered again, not strand the session',
    );

    final summary = await finalize.call(completed);

    // The retry does not launder the grade: c1's terminal outcome is still
    // wrong, so its box drops while c2's rises.
    final c1 = await progress.findByCard('c1');
    final c2 = await progress.findByCard('c2');
    expect(c1!.box, lessThan(3), reason: 'a relearned card is demoted');
    expect(c2!.box, greaterThan(3), reason: 'a remembered card is promoted');
    expect(summary.reviewedCount, 2);
  });

  // A finalize retry must re-apply nothing (`srs-8-box-policy.md` §7).
  test('finalizing twice schedules the same cards once', () async {
    await dueCard('c1', 'one');

    final completed = await answerAll(
      await startDueReview(),
      (_) => SrsBinaryAction.remembered,
    );
    await finalize.call(completed);
    final afterFirst = await progress.findByCard('c1');

    await finalize.call(completed);
    final afterSecond = await progress.findByCard('c1');

    expect(afterSecond!.box, afterFirst!.box);
    expect(afterSecond.revision, afterFirst.revision);
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
