import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/match_round.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';

/// WBS 5.6.6 — the Match board round (SM-MATCH-v1; answer-study-stage.md §21,
/// §72). Only a correct pairing locks a tile; wrong/almost record a sticky lapse
/// that a later correct completion never clears.
void main() {
  MatchRound round() => MatchRound.of(const ['a', 'b', 'c']);

  test('a clean round locks every pair and all pass', () {
    var r = round();
    for (final id in const ['a', 'b', 'c']) {
      r = r.resolve(termPairId: id, outcome: ModeOutcome.correct);
    }
    expect(r.isComplete, isTrue);
    expect(r.lockedCount, 3);
    for (final id in const ['a', 'b', 'c']) {
      expect(r.passedFor(id), isTrue);
      expect(r.outcomeFor(id), ModeOutcome.correct);
    }
  });

  test('a wrong pairing lapses the card without locking it', () {
    final r = round().resolve(termPairId: 'a', outcome: ModeOutcome.wrong);
    expect(r.hasLapsed('a'), isTrue);
    expect(r.isLocked('a'), isFalse);
    expect(r.lockedCount, 0);
    expect(r.isComplete, isFalse);
    expect(r.passedFor('a'), isFalse);
    expect(r.outcomeFor('a'), ModeOutcome.wrong);
  });

  test('almost lapses the card and is kept as its outcome', () {
    final r = round().resolve(termPairId: 'b', outcome: ModeOutcome.almost);
    expect(r.hasLapsed('b'), isTrue);
    expect(r.isLocked('b'), isFalse);
    expect(r.outcomeFor('b'), ModeOutcome.almost);
  });

  test(
    'a later correct completes a lapsed tile but keeps the lapse (SM-MATCH-004)',
    () {
      final r = round()
          .resolve(termPairId: 'a', outcome: ModeOutcome.wrong)
          .resolve(termPairId: 'a', outcome: ModeOutcome.correct);
      expect(r.isLocked('a'), isTrue);
      expect(r.lockedCount, 1);
      // The lapse is sticky — the card still fails the round and repeats.
      expect(r.passedFor('a'), isFalse);
      expect(r.outcomeFor('a'), ModeOutcome.wrong);
    },
  );

  test('the first lapse sticks when a card lapses twice', () {
    final r = round()
        .resolve(termPairId: 'c', outcome: ModeOutcome.wrong)
        .resolve(termPairId: 'c', outcome: ModeOutcome.almost);
    expect(r.outcomeFor('c'), ModeOutcome.wrong);
  });

  test('a correct pairing is idempotent and never re-locks', () {
    final r = round()
        .resolve(termPairId: 'a', outcome: ModeOutcome.correct)
        .resolve(termPairId: 'a', outcome: ModeOutcome.correct);
    expect(r.lockedCount, 1);
  });

  test('reviewed is not a Match classification and is ignored', () {
    final r = round().resolve(termPairId: 'a', outcome: ModeOutcome.reviewed);
    expect(r.hasLapsed('a'), isFalse);
    expect(r.isLocked('a'), isFalse);
  });

  test('a mixed round completes once every tile is locked', () {
    final r = round()
        .resolve(termPairId: 'a', outcome: ModeOutcome.correct)
        .resolve(termPairId: 'b', outcome: ModeOutcome.wrong)
        .resolve(termPairId: 'b', outcome: ModeOutcome.correct)
        .resolve(termPairId: 'c', outcome: ModeOutcome.almost)
        .resolve(termPairId: 'c', outcome: ModeOutcome.correct);
    expect(r.isComplete, isTrue);
    expect(r.passedFor('a'), isTrue);
    expect(r.passedFor('b'), isFalse);
    expect(r.passedFor('c'), isFalse);
    expect(r.outcomeFor('b'), ModeOutcome.wrong);
    expect(r.outcomeFor('c'), ModeOutcome.almost);
  });
}
