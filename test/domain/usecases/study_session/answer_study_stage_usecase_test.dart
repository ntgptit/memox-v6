import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';

/// WBS 5.6.3 — answering a stage evaluates, persists an intermediate attempt +
/// advanced checkpoint atomically, and returns the next runtime
/// (`answer-study-stage.md`).
void main() {
  final now = DateTime.utc(2026, 7, 23, 13);
  late _CapturingRepo repo;
  late AnswerStudyStageUseCase useCase;

  setUp(() {
    repo = _CapturingRepo();
    useCase = AnswerStudyStageUseCase(
      sessions: repo,
      factory: StudyModeFactory.standard(),
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
    );
  });

  StudyRuntimeState runtime() => StudyRuntimeState.assemble(
    session: StudySession(
      id: 's1',
      type: SessionType.newLearning,
      deckId: 'd1',
      scope: SessionScope.subtree,
      state: SessionState.active,
      revision: 0,
      snapshotVersion: 1,
      scheduleSrs: true,
      startedAt: now,
      finalizedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
    stages: const <StudyModeType>[StudyModeType.review, StudyModeType.match],
    cardSnapshots: <SessionCardSnapshot>[_card('a', 0), _card('b', 1)],
    currentOrder: const SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: <String>['a', 'b'],
    ),
  );

  ReviewInput review(StudyRuntimeState state) => ReviewInput(
    sessionId: 's1',
    cardId: state.position.currentCardId!,
    eventId: 'ev-${state.position.cardPosition}',
  );

  test(
    'a passing review answer persists a non-terminal attempt and advances',
    () async {
      final state = runtime();
      final next = await useCase.call(state, review(state));

      expect(next.position.cardPosition, 1, reason: 'cursor advanced');
      expect(repo.lastAttempt?.isTerminal, isFalse);
      expect(repo.lastAttempt?.outcome, 'reviewed');
      expect(repo.lastAttempt?.modeId, 'review');
      expect(repo.lastCheckpoint?.cardPosition, 1);
      expect(repo.lastNewOrder, isNull, reason: 'same round');
    },
  );

  test(
    'answering the last card advances to the next stage with a new order',
    () async {
      var state = runtime();
      state = await useCase.call(state, review(state)); // card a
      state = await useCase.call(state, review(state)); // card b (last)

      expect(
        state.currentMode,
        StudyModeType.match,
        reason: 'advanced to stage 1',
      );
      expect(state.position.roundIndex, 2, reason: 'monotonic new round');
      expect(repo.lastNewOrder, isNotNull);
      expect(repo.lastNewOrder?.roundIndex, 2);
      expect(repo.lastNewOrder?.cardIds.toSet(), {'a', 'b'});
    },
  );

  test('the idempotency key is deterministic per position and event', () async {
    final state = runtime();
    await useCase.call(state, review(state));
    final first = repo.lastAttempt?.idempotencyKey;
    // Re-answering the same position/event yields the same key (retry-safe).
    await useCase.call(state, review(state));
    expect(repo.lastAttempt?.idempotencyKey, first);
    expect(first, 's1:0:1:0:ev-0');
  });
}

SessionCardSnapshot _card(String id, int order) => SessionCardSnapshot(
  id: 'sc-$id',
  sessionId: 's1',
  cardId: id,
  displayOrder: order,
  term: id.toUpperCase(),
  meaning: 'meaning-$id',
  contentVersion: 1,
  progressBox: 0,
  progressRevision: 0,
);

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}

/// Captures the atomic save; other ops are unused by this use case.
class _CapturingRepo implements StudySessionRepository {
  StudyAttempt? lastAttempt;
  SessionCheckpoint? lastCheckpoint;
  SessionRoundOrder? lastNewOrder;

  @override
  Future<void> saveAttemptWithCheckpoint({
    required StudyAttempt attempt,
    required SessionCheckpoint checkpoint,
    SessionRoundOrder? newRoundOrder,
  }) async {
    lastAttempt = attempt;
    lastCheckpoint = checkpoint;
    lastNewOrder = newRoundOrder;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}
