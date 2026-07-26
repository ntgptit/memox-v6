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
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

import '../../../support/restart_harness.dart';

/// WBS 5.6.12 — leaving a session and coming back
/// (`exit-study-session.md`; `resume-study-session.md`).
///
/// Exit is not finalize: the session stays resumable and its committed
/// answers survive. Resume rebuilds from the committed checkpoint rather than
/// from anything the UI remembered — §1: "Resume không được tái tính mastery
/// queue từ UI memory; round state phải đến từ committed checkpoint."
///
/// Driven over a real file-backed store through [RestartHarness], so the
/// second half runs on a fresh connection and object graph, exactly as a
/// process restart does. Nothing in memory can carry the answer across.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  // Declared outside `wire` on purpose: a restart replaces the object graph
  // but not the id space. Rebuilding these per wiring would restart their
  // counters and mint an id the store already holds — a collision production
  // cannot have, since it generates UUIDv7.
  late _SeqIds startIds;
  late _SeqIds answerIds;
  late _SeqIds finalIds;

  setUp(() {
    startIds = _SeqIds('start');
    answerIds = _SeqIds('answer');
    finalIds = _SeqIds('final');
  });

  /// The five use cases a study surface holds, rebuilt against [database] —
  /// which is what a restart hands the app.
  ({
    DriftStudySessionRepository sessions,
    DriftLearningProgressRepository progress,
    StartStudySessionUseCase start,
    AnswerStudyStageUseCase answer,
    LoadStudyRuntimeUseCase loadRuntime,
    FinalizeStudySessionUseCase finalize,
  })
  wire(db.AppDatabase database) {
    final sessions = DriftStudySessionRepository(database);
    final progress = DriftLearningProgressRepository(database);
    return (
      sessions: sessions,
      progress: progress,
      start: StartStudySessionUseCase(
        progress: progress,
        cards: DriftFlashcardRepository(database),
        sessions: sessions,
        clock: _FixedClock(now),
        idGenerator: startIds,
      ),
      answer: AnswerStudyStageUseCase(
        sessions: sessions,
        factory: StudyModeFactory.standard(),
        clock: _FixedClock(now),
        idGenerator: answerIds,
      ),
      loadRuntime: LoadStudyRuntimeUseCase(sessions: sessions),
      finalize: FinalizeStudySessionUseCase(
        sessions: sessions,
        progress: progress,
        applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
        clock: _FixedClock(now),
        idGenerator: finalIds,
      ),
    );
  }

  Future<void> seed(db.AppDatabase database) async {
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
      ('c3', 'three'),
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
  }

  Future<StudyRuntimeState> answerOne(
    AnswerStudyStageUseCase answer,
    StudyRuntimeState runtime,
    SrsBinaryAction action,
  ) {
    final cardId = runtime.position.currentCardId!;
    return answer.call(
      runtime,
      SrsBinaryReviewInput(
        sessionId: runtime.session.id,
        cardId: cardId,
        roundIndex: runtime.position.roundIndex,
        eventId: 'srs-$cardId-${action.name}-r${runtime.position.roundIndex}',
        action: action,
      ),
    );
  }

  test('a session left mid-way resumes where it was committed', () async {
    final harness = RestartHarness.create();
    await seed(harness.database);

    var app = wire(harness.database);
    await app.start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    var runtime = (await app.loadRuntime())!;
    final firstCard = runtime.position.currentCardId;
    runtime = await answerOne(app.answer, runtime, SrsBinaryAction.remembered);
    final positionBefore = runtime.position.cardPosition;
    final attemptsBefore = await app.sessions.attempts(runtime.session.id);
    // Leaving is not finalizing: the session is still the active one.
    expect(runtime.session.state, SessionState.active);

    // The restart. Nothing survives but the store.
    app = wire(await harness.restart());
    final resumed = await app.loadRuntime();

    expect(resumed, isNotNull, reason: 'the session is still resumable');
    expect(resumed!.session.id, runtime.session.id);
    expect(
      resumed.position.cardPosition,
      positionBefore,
      reason: 'the committed checkpoint decides the position, not UI memory',
    );
    expect(
      resumed.position.currentCardId,
      isNot(firstCard),
      reason: 'the answered card is behind us',
    );
    // §1: "Attempt đã commit không được submit lại."
    expect(
      await app.sessions.attempts(resumed.session.id),
      hasLength(attemptsBefore.length),
    );
  });

  // `exit-study-session.md` §1: "Exit không tạo completed summary hoặc goal
  // contribution." Leaving writes nothing that looks like finishing.
  test('leaving mid-session grades no cards', () async {
    final harness = RestartHarness.create();
    await seed(harness.database);

    var app = wire(harness.database);
    await app.start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    var runtime = (await app.loadRuntime())!;
    final answered = runtime.position.currentCardId!;
    runtime = await answerOne(app.answer, runtime, SrsBinaryAction.remembered);

    app = wire(await harness.restart());
    final progress = await app.progress.findByCard(answered);

    // The SRS grade is aggregated at finalize; an answered-but-unfinalized
    // card keeps the box it was due in.
    expect(progress!.box, 3);
  });

  test('a resumed session can be finished and finalized once', () async {
    final harness = RestartHarness.create();
    await seed(harness.database);

    var app = wire(harness.database);
    await app.start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    var runtime = (await app.loadRuntime())!;
    runtime = await answerOne(app.answer, runtime, SrsBinaryAction.remembered);

    app = wire(await harness.restart());
    runtime = (await app.loadRuntime())!;
    for (var step = 0; step < 20 && !runtime.isComplete; step++) {
      runtime = await answerOne(
        app.answer,
        runtime,
        SrsBinaryAction.remembered,
      );
    }

    expect(runtime.isComplete, isTrue);
    final summary = await app.finalize.call(runtime);

    // Every card graded exactly once across the two halves of the session.
    expect(summary.reviewedCount, 3);
    final persisted = await app.sessions.findById(runtime.session.id);
    expect(persisted!.state, SessionState.completed);
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
