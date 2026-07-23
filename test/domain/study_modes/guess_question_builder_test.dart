import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/study_modes/guess_question_builder.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';

/// WBS 5.6.7 — the Guess question builder produces exactly five distinct-meaning
/// options, one correct, deterministically (`guess-card-meaning.md` §§1,4).
void main() {
  const builder = GuessQuestionBuilder();

  List<GuessCandidate> pool(int n) => List<GuessCandidate>.generate(
    n,
    (i) => GuessCandidate(cardId: 'c$i', meaning: 'meaning-$i'),
  );

  GuessQuestion build(List<GuessCandidate> cards, {GuessCandidate? target}) =>
      builder.build(
        sessionId: 's1',
        roundIndex: 1,
        target: target ?? cards.first,
        pool: cards,
      );

  test('builds exactly five options: one correct + four distractors', () {
    final question = build(pool(6));
    expect(question.options.length, kGuessOptionCount);
    // The correct choice appears exactly once.
    expect(
      question.options
          .where((o) => o.choiceId == question.correctChoiceId)
          .length,
      1,
    );
    // Five distinct normalized meanings.
    expect(
      question.options
          .map((o) => StringUtils.comparisonKey(o.meaning))
          .toSet()
          .length,
      kGuessOptionCount,
    );
  });

  test(
    'the correct option carries the target meaning; distractors are others',
    () {
      final cards = pool(6);
      final question = build(cards, target: cards[2]);
      expect(question.correctChoiceId, 'c2');
      final correct = question.options.firstWhere(
        (o) => o.choiceId == question.correctChoiceId,
      );
      expect(correct.meaning, 'meaning-2');
      // Every distractor references a different card than the target.
      for (final option in question.options) {
        if (option.choiceId == question.correctChoiceId) continue;
        expect(option.sourceCardId, isNot('c2'));
      }
    },
  );

  test(
    'is deterministic — identical inputs replay the same ordered options',
    () {
      final cards = pool(6);
      final first = build(cards).options.map((o) => o.choiceId).toList();
      final again = build(cards).options.map((o) => o.choiceId).toList();
      expect(again, first);
    },
  );

  test(
    'a duplicate normalized meaning does not count as a distinct distractor',
    () {
      final cards = <GuessCandidate>[
        const GuessCandidate(cardId: 'c0', meaning: 'alpha'),
        const GuessCandidate(cardId: 'c1', meaning: 'beta'),
        const GuessCandidate(
          cardId: 'c2',
          meaning: 'BETA',
        ), // dup of c1 normalized
        const GuessCandidate(cardId: 'c3', meaning: 'gamma'),
        const GuessCandidate(cardId: 'c4', meaning: 'delta'),
      ];
      // Only 3 distinct distractor meanings (beta, gamma, delta) → fails closed.
      expect(
        () => build(cards),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.code,
            'code',
            'insufficient-distinct-meanings',
          ),
        ),
      );
    },
  );

  test('too few distinct meanings fails closed (no reduced option count)', () {
    expect(() => build(pool(4)), throwsA(isA<ValidationFailure>()));
  });
}
