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
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 5.6.11 — the relearn loop composes end to end (`relearn-cards.md`).
///
/// The flow a learner takes from the Study Result's `Review mistakes`: a due
/// session finalizes with a missed card, its committed summary becomes the
/// relearn queue, and that session runs and finalizes on its own.
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

  Future<StudyRuntimeState> answerAll(
    StudyRuntimeState from,
    SrsBinaryAction Function(String cardId, int round) actionFor,
  ) async {
    var runtime = from;
    for (var step = 0; step < 50 && !runtime.isComplete; step++) {
      final cardId = runtime.position.currentCardId;
      if (cardId == null) break;
      final round = runtime.position.roundIndex;
      final action = actionFor(cardId, round);
      runtime = await answer.call(
        runtime,
        SrsBinaryReviewInput(
          sessionId: runtime.session.id,
          cardId: cardId,
          roundIndex: round,
          eventId: 'srs-$cardId-${action.name}-r$round',
          action: action,
        ),
      );
    }
    return runtime;
  }

  /// Runs a due session over the seeded cards, missing [missed] on the first
  /// round and passing it afterwards, then finalizes.
  ///
  /// Missing it on *every* round never completes, by design: §2's sticky wrong
  /// requires the card to pass a mastery retry round before the session can
  /// end, while its terminal grade stays wrong. Returns the committed summary
  /// with the id of the session that produced it — the summary carries no
  /// session id of its own.
  Future<({StudySessionSummary summary, String sessionId})>
  finishDueSessionMissing(String missed) async {
    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
    final runtime = await loadRuntime();
    final completed = await answerAll(
      runtime!,
      (cardId, round) => cardId == missed && round == 1
          ? SrsBinaryAction.relearn
          : SrsBinaryAction.remembered,
    );
    return (
      summary: await finalize.call(completed),
      sessionId: completed.session.id,
    );
  }

  // §1: "Relearn queue được tạo từ terminal outcomes đã commit của một session
  // đã finalize, không từ transient wrong tap."
  test('the queue is the finalized summary, not the whole scope', () async {
    await dueCard('c1', 'one');
    await dueCard('c2', 'two');
    await dueCard('c3', 'three');

    final (:summary, :sessionId) = await finishDueSessionMissing('c2');
    expect(summary.missedCardIds, <String>['c2']);

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.relearn,
      relearnCardIds: summary.missedCardIds,
    );
    final relearn = await loadRuntime();

    expect(relearn!.session.type, SessionType.relearn);
    expect(relearn.position.roundCardIds, <String>['c2']);
  });

  // The active-session conflict added in #186 must not block the very handoff
  // the Study Result offers: finalize releases the slot, so `Review mistakes`
  // has one to take.
  test(
    'relearn can start straight after the source session finalizes',
    () async {
      await dueCard('c1', 'one');
      await dueCard('c2', 'two');

      final (:summary, sessionId: _) = await finishDueSessionMissing('c2');

      // No throw: the finalized source is no longer active.
      final relearn = await start.call(
        deckId: 'd1',
        scope: SessionScope.subtree,
        type: SessionType.relearn,
        relearnCardIds: summary.missedCardIds,
      );
      expect(relearn.type, SessionType.relearn);
    },
  );

  // §1: "Relearn không xóa Attempts trước đó."
  test('the source session keeps its attempts', () async {
    await dueCard('c1', 'one');
    await dueCard('c2', 'two');

    final (:summary, :sessionId) = await finishDueSessionMissing('c2');
    final sourceId = sessionId;
    final before = await sessions.attempts(sourceId);
    expect(before, isNotEmpty);

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.relearn,
      relearnCardIds: summary.missedCardIds,
    );
    final relearn = await loadRuntime();
    final done = await answerAll(
      relearn!,
      (_, _) => SrsBinaryAction.remembered,
    );
    await finalize.call(done);

    expect(await sessions.attempts(sourceId), hasLength(before.length));
  });

  // `srs-binary-review.md` §2: a relearn session schedules from the persisted
  // current box, so Remembered can promote a card a previous session demoted.
  // "Đây là behavior đã chấp nhận, không phải undo trong cùng transaction."
  test(
    'a passed relearn schedules from the demoted box, not the old one',
    () async {
      await dueCard('c1', 'one');
      await dueCard('c2', 'two');

      final (:summary, sessionId: _) = await finishDueSessionMissing('c2');
      final demoted = await progress.findByCard('c2');
      expect(demoted!.box, lessThan(3), reason: 'the miss demoted it');

      await start.call(
        deckId: 'd1',
        scope: SessionScope.subtree,
        type: SessionType.relearn,
        relearnCardIds: summary.missedCardIds,
      );
      final relearn = await loadRuntime();
      final done = await answerAll(
        relearn!,
        (_, _) => SrsBinaryAction.remembered,
      );
      await finalize.call(done);

      final promoted = await progress.findByCard('c2');
      expect(
        promoted!.box,
        greaterThan(demoted.box),
        reason: 'the pass promotes from where the demotion left it',
      );
    },
  );

  // ST-TYPE-015/016 through the whole flow rather than at the resolver: two
  // missed cards cannot fill a five-option Guess pool, so the plan is binary.
  test('a small relearn queue runs the binary plan', () async {
    await dueCard('c1', 'one');
    await dueCard('c2', 'two');

    final (:summary, sessionId: _) = await finishDueSessionMissing('c2');
    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.relearn,
      relearnCardIds: summary.missedCardIds,
    );

    final relearn = await loadRuntime();
    expect(relearn!.stages, <StudyModeType>[StudyModeType.srsBinaryReview]);
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
