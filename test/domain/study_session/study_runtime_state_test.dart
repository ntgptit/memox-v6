import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';

/// WBS 5.6.3 (domain part) — the runtime read model projects committed state
/// (`resume-study-session.md` §7; GAP-B initial position).
void main() {
  final now = DateTime.utc(2026, 7, 23, 12);
  const stages = <StudyModeType>[StudyModeType.review, StudyModeType.match];

  StudySession session() => StudySession(
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
  );

  List<SessionCardSnapshot> cards() => <SessionCardSnapshot>[
    SessionCardSnapshot(
      id: 'sc-a',
      sessionId: 's1',
      cardId: 'a',
      displayOrder: 0,
      term: 'A',
      meaning: 'alpha',
      contentVersion: 1,
      progressBox: 0,
      progressRevision: 0,
    ),
    SessionCardSnapshot(
      id: 'sc-b',
      sessionId: 's1',
      cardId: 'b',
      displayOrder: 1,
      term: 'B',
      meaning: 'beta',
      contentVersion: 1,
      progressBox: 0,
      progressRevision: 0,
    ),
  ];

  const order = SessionRoundOrder(
    id: 'ro1',
    sessionId: 's1',
    roundIndex: 1,
    seed: 1,
    cardIds: <String>['b', 'a'],
  );

  test(
    'with no checkpoint the runtime is the first card of the initial order',
    () {
      final runtime = StudyRuntimeState.assemble(
        session: session(),
        stages: stages,
        cardSnapshots: cards(),
        currentOrder: order,
      );
      expect(runtime.position.stageIndex, 0);
      expect(runtime.position.roundIndex, 1);
      expect(runtime.currentMode, StudyModeType.review);
      expect(
        runtime.currentCard?.cardId,
        'b',
        reason: 'first of the shuffled order',
      );
      expect(runtime.currentCard?.meaning, 'beta');
      expect(runtime.totalCards, 2);
      expect(runtime.roundCardCount, 2);
      expect(runtime.isComplete, isFalse);
    },
  );

  test('a checkpoint drives the stage/round/cursor and failed set', () {
    final runtime = StudyRuntimeState.assemble(
      session: session(),
      stages: stages,
      cardSnapshots: cards(),
      currentOrder: order,
      checkpoint: SessionCheckpoint(
        id: 'cp1',
        sessionId: 's1',
        stageIndex: 1,
        roundIndex: 1,
        cardPosition: 1,
        failedCardIds: const <String>['a'],
        timerStateJson: '{}',
        stateVersion: 2,
        updatedAt: now,
      ),
    );
    expect(runtime.currentMode, StudyModeType.match);
    expect(runtime.position.cardPosition, 1);
    expect(runtime.currentCard?.cardId, 'a', reason: 'second of the order');
    expect(runtime.position.failedCardIds, <String>['a']);
    expect(runtime.answeredInRound, 1);
  });
}
