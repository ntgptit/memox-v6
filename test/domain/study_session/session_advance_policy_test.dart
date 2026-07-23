import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';

/// WBS 5.6.3 (domain part) — the session advance state machine
/// (`answer-study-stage.md` §3, `resume-study-session.md` §§58-60).
void main() {
  const policy = SessionAdvancePolicy();
  const stages = <StudyModeType>[StudyModeType.match, StudyModeType.guess];
  final allCards = <String>['a', 'b', 'c'];

  SessionPosition pos({
    int stage = 0,
    int round = 1,
    List<String>? order,
    int cursor = 0,
    List<String> failed = const <String>[],
  }) => SessionPosition(
    stageIndex: stage,
    roundIndex: round,
    roundCardIds: order ?? allCards,
    cardPosition: cursor,
    failedCardIds: failed,
  );

  SessionPosition advance(SessionPosition current, {required bool passed}) =>
      policy.next(
        sessionId: 'sess-1',
        stages: stages,
        allSessionCardIds: allCards,
        current: current,
        currentCardPassed: passed,
      );

  test('a passing answer with cards left advances the cursor only', () {
    final next = advance(pos(cursor: 0), passed: true);
    expect(next.stageIndex, 0);
    expect(next.roundIndex, 1);
    expect(next.cardPosition, 1);
    expect(next.failedCardIds, isEmpty);
    expect(next.phase, SessionPhase.inRound);
  });

  test('a failing answer records the card in the failed set', () {
    final next = advance(pos(cursor: 0), passed: false);
    expect(next.cardPosition, 1);
    expect(next.failedCardIds, <String>['a']);
  });

  test(
    'a clean last card advances to the next stage, roundIndex monotonic',
    () {
      // Last card of stage 0's round 3 with no failures → stage 1 at round 4
      // (session-global monotonic round index, never reset per stage).
      final next = advance(pos(stage: 0, round: 3, cursor: 2), passed: true);
      expect(next.stageIndex, 1);
      expect(next.roundIndex, 4);
      expect(next.cardPosition, 0);
      expect(next.roundCardIds.toSet(), allCards.toSet(), reason: 'all cards');
      expect(next.failedCardIds, isEmpty);
    },
  );

  test('a last card with failures opens a new round over the failed set', () {
    // 'a' failed earlier; 'c' (last card) fails now → next round is {a, c}.
    final next = advance(
      pos(stage: 0, cursor: 2, failed: <String>['a']),
      passed: false,
    );
    expect(next.stageIndex, 0, reason: 'same stage — mastery retry');
    expect(next.roundIndex, 2);
    expect(next.roundCardIds.toSet(), {'a', 'c'});
    expect(next.cardPosition, 0);
    expect(next.failedCardIds, isEmpty, reason: 'accumulator resets per round');
  });

  test('a later pass never clears an already-failed card', () {
    // 'a' already failed; answering it passing keeps it failed for the round.
    final next = advance(
      pos(
        stage: 0,
        order: <String>['a', 'b'],
        cursor: 0,
        failed: <String>['a'],
      ),
      passed: true,
    );
    expect(next.failedCardIds, <String>['a']);
  });

  test('the last stage cleared completes the session', () {
    final next = advance(pos(stage: 1, cursor: 2), passed: true);
    expect(next.phase, SessionPhase.sessionComplete);
    expect(next.currentCardId, isNull);
  });

  test('currentCardId points at the cursor while in a round', () {
    expect(pos(order: <String>['x', 'y'], cursor: 1).currentCardId, 'y');
  });

  // WBS 5.6.11 — mastery rounds: the failed set is deduped and retry rounds
  // repeat with no limit until a round finishes clean.

  test('a card already in the failed set is not duplicated on a later fail', () {
    // Defensive dedup: if the cursor card is already failed (e.g. a checkpoint
    // restored mid-round), failing it again keeps a single entry.
    final next = advance(
      pos(order: <String>['a', 'b'], cursor: 0, failed: <String>['a']),
      passed: false,
    );
    expect(next.failedCardIds, <String>['a']);
  });

  test('mastery retry rounds repeat with no limit until a clean round', () {
    // A card that keeps failing spawns round after round in the same stage; the
    // round index climbs and the failed card stays the sole member.
    var position = pos(order: <String>['a'], round: 1, cursor: 0);
    for (var round = 2; round <= 5; round++) {
      position = advance(position, passed: false);
      expect(position.stageIndex, 0, reason: 'still the same mastery stage');
      expect(position.roundIndex, round);
      expect(position.roundCardIds, <String>['a']);
      expect(position.cardPosition, 0);
      expect(position.phase, SessionPhase.inRound);
    }
    // Only a clean round finally advances to the next stage.
    final done = advance(position, passed: true);
    expect(done.stageIndex, 1);
  });
}
