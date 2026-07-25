import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// WBS 5.5.4 — the six concrete strategies implement only pure hooks + evidence
/// rules, each citing its owning spec / decision-table row.
void main() {
  group('Review', () {
    test('a completed browse yields canonical reviewed', () {
      const strategy = ReviewStudyModeStrategy();
      final e = strategy.evaluate(
        const ReviewInput(sessionId: 's', cardId: 'c', eventId: 'e'),
      );
      expect(e.mode, StudyModeType.review);
      expect(e.outcome, ModeOutcome.reviewed);
    });
  });

  group('SRS Binary Review', () {
    const strategy = SrsBinaryReviewStudyModeStrategy();
    SrsBinaryReviewInput input(SrsBinaryAction a) => SrsBinaryReviewInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      action: a,
    );

    test('Remembered → correct, Relearn → wrong', () {
      expect(
        strategy.evaluate(input(SrsBinaryAction.remembered)).outcome,
        ModeOutcome.correct,
      );
      expect(
        strategy.evaluate(input(SrsBinaryAction.relearn)).outcome,
        ModeOutcome.wrong,
      );
    });
  });

  group('Guess', () {
    const strategy = GuessStudyModeStrategy();
    List<GuessOption> fiveOptions() => <GuessOption>[
      const GuessOption(choiceId: 'o1', meaning: 'alpha', sourceCardId: 'c'),
      const GuessOption(choiceId: 'o2', meaning: 'beta', sourceCardId: 'd2'),
      const GuessOption(choiceId: 'o3', meaning: 'gamma', sourceCardId: 'd3'),
      const GuessOption(choiceId: 'o4', meaning: 'delta', sourceCardId: 'd4'),
      const GuessOption(choiceId: 'o5', meaning: 'epsilon', sourceCardId: 'd5'),
    ];
    GuessInput input({required String selected, List<GuessOption>? options}) =>
        GuessInput(
          sessionId: 's',
          cardId: 'c',
          roundIndex: 0,
          eventId: 'e',
          options: options ?? fiveOptions(),
          correctChoiceId: 'o1',
          selectedChoiceId: selected,
        );

    test('selecting the correct choice id → correct; another → wrong', () {
      expect(
        strategy.evaluate(input(selected: 'o1')).outcome,
        ModeOutcome.correct,
      );
      expect(
        strategy.evaluate(input(selected: 'o3')).outcome,
        ModeOutcome.wrong,
      );
    });

    test('anything but exactly five valid choices is a validation error', () {
      // Only four options.
      expect(
        () => strategy.evaluate(
          input(selected: 'o1', options: fiveOptions().take(4).toList()),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      // Two options normalize to the same meaning.
      final dup = fiveOptions()
        ..[4] = const GuessOption(
          choiceId: 'o5',
          meaning: 'ALPHA',
          sourceCardId: 'd5',
        );
      expect(
        () => strategy.evaluate(input(selected: 'o1', options: dup)),
        throwsA(isA<ValidationFailure>()),
      );
      // A distractor drawn from the current card.
      final ownDistractor = fiveOptions()
        ..[1] = const GuessOption(
          choiceId: 'o2',
          meaning: 'beta',
          sourceCardId: 'c',
        );
      expect(
        () => strategy.evaluate(input(selected: 'o1', options: ownDistractor)),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Recall', () {
    const strategy = RecallStudyModeStrategy();
    RecallInput input({
      required RecallResolution resolution,
      bool revealed = true,
      int elapsedMs = 20000,
    }) => RecallInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      revealed: revealed,
      resolution: resolution,
      elapsedActiveMs: elapsedMs,
    );

    test('Remembered → correct, Forgot → wrong', () {
      expect(
        strategy
            .evaluate(input(resolution: RecallResolution.remembered))
            .outcome,
        ModeOutcome.correct,
      );
      expect(
        strategy.evaluate(input(resolution: RecallResolution.forgot)).outcome,
        ModeOutcome.wrong,
      );
    });

    test('a reached 20s deadline → wrong with reason timeout', () {
      final e = strategy.evaluate(
        input(resolution: RecallResolution.timeout, revealed: true),
      );
      expect(e.outcome, ModeOutcome.wrong);
      expect(e.reason, ModeOutcomeReason.timeout);
    });

    test('self-grade before reveal and premature timeout are rejected', () {
      expect(
        () => strategy.evaluate(
          input(resolution: RecallResolution.remembered, revealed: false),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => strategy.evaluate(
          input(resolution: RecallResolution.timeout, elapsedMs: 19999),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Match', () {
    const strategy = MatchStudyModeStrategy();
    MatchInput input({
      required String selectedPair,
      String termMeaning = 'to run',
      String selectedMeaning = 'to run',
    }) => MatchInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      termPairId: 'p1',
      selectedMeaningPairId: selectedPair,
      termMeaning: termMeaning,
      selectedMeaning: selectedMeaning,
    );

    test('SM-MATCH-001: same pair id → correct', () {
      expect(
        strategy.evaluate(input(selectedPair: 'p1')).outcome,
        ModeOutcome.correct,
      );
    });

    test('SM-MATCH-002: different pair id and meaning → wrong', () {
      final e = strategy.evaluate(
        input(selectedPair: 'p2', selectedMeaning: 'to walk'),
      );
      expect(e.outcome, ModeOutcome.wrong);
      expect(e.reason, isNull);
    });

    test(
      'SM-MATCH-003: different pair id, equal normalized meaning → almost',
      () {
        final e = strategy.evaluate(
          input(selectedPair: 'p2', selectedMeaning: 'To Run'),
        );
        expect(e.outcome, ModeOutcome.almost);
        expect(e.reason, ModeOutcomeReason.duplicateNormalizedMeaning);
      },
    );

    test('SM-MATCH-007: a missing tile is an invalid interaction', () {
      expect(
        () => strategy.evaluate(input(selectedPair: '')),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('Fill', () {
    const strategy = FillStudyModeStrategy();
    FillInput input({
      required String raw,
      List<String>? accepted,
      String policy = kFillComparePolicyV1,
      bool ime = false,
    }) => FillInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      rawInput: raw,
      acceptedAnswers: accepted ?? const <String>['con mèo', 'mèo'],
      comparisonPolicyId: policy,
      imeComposing: ime,
    );

    test('SM-FILL-002: differs only by case/whitespace → correct', () {
      expect(
        strategy.evaluate(input(raw: '  Con   Mèo ')).outcome,
        ModeOutcome.correct,
      );
    });

    test('SM-FILL-004: matches an accepted alternative → correct', () {
      expect(strategy.evaluate(input(raw: 'Mèo')).outcome, ModeOutcome.correct);
    });

    test('SM-FILL-003/005: differs by diacritic → wrong (no fuzzy pass)', () {
      expect(
        strategy.evaluate(input(raw: 'con meo')).outcome,
        ModeOutcome.wrong,
      );
    });

    test('SM-FILL-001/006/008: blank, IME and bad policy are rejected', () {
      expect(
        () => strategy.evaluate(input(raw: '   ')),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => strategy.evaluate(input(raw: 'con mèo', ime: true)),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () =>
            strategy.evaluate(input(raw: 'con mèo', policy: 'fill-compare-v2')),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
