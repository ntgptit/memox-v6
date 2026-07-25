import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// WBS 5.5.6 — the shared contract every strategy honours, driven through the
/// factory, plus the named boundary cases (Guess five-options, Recall 20s race,
/// binary self-grade, Fill normalization, Match classification). Per-strategy
/// row coverage lives in `strategies_test.dart`; factory resolution in
/// `study_mode_factory_test.dart`.
void main() {
  final factory = StudyModeFactory.standard();

  // A valid, evidence-producing input for each mode.
  final validInput = <StudyModeType, StudyModeInput>{
    StudyModeType.review: const ReviewInput(
      sessionId: 's',
      cardId: 'c',
      eventId: 'e',
    ),
    StudyModeType.match: const MatchInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      termPairId: 'p1',
      selectedMeaningPairId: 'p1',
      termMeaning: 'to run',
      selectedMeaning: 'to run',
    ),
    StudyModeType.guess: const GuessInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      options: <GuessOption>[
        GuessOption(choiceId: 'o1', meaning: 'alpha', sourceCardId: 'c'),
        GuessOption(choiceId: 'o2', meaning: 'beta', sourceCardId: 'd2'),
        GuessOption(choiceId: 'o3', meaning: 'gamma', sourceCardId: 'd3'),
        GuessOption(choiceId: 'o4', meaning: 'delta', sourceCardId: 'd4'),
        GuessOption(choiceId: 'o5', meaning: 'epsilon', sourceCardId: 'd5'),
      ],
      correctChoiceId: 'o1',
      selectedChoiceId: 'o1',
    ),
    StudyModeType.recall: const RecallInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      revealed: true,
      resolution: RecallResolution.remembered,
      elapsedActiveMs: 5000,
    ),
    StudyModeType.fill: const FillInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      rawInput: 'con mèo',
      acceptedAnswers: <String>['con mèo'],
    ),
    StudyModeType.srsBinaryReview: const SrsBinaryReviewInput(
      sessionId: 's',
      cardId: 'c',
      roundIndex: 0,
      eventId: 'e',
      action: SrsBinaryAction.remembered,
    ),
  };

  group('shared contract over the six factory strategies', () {
    for (final type in StudyModeType.values) {
      test('$type: evidence carries the mode and is deterministic', () {
        final strategy = factory.create(type);
        final input = validInput[type]!;

        final first = strategy.evaluate(input);
        final second = strategy.evaluate(input);

        expect(first.mode, type);
        expect(first.mappingVersion, 1);
        expect(first.cardId, 'c');
        expect(first.eventId, 'e');
        // Pure: identical input yields identical evidence.
        expect(second.mode, first.mode);
        expect(second.outcome, first.outcome);
        expect(second.reason, first.reason);
      });

      test('$type: a foreign input type is rejected, not coerced', () {
        expect(
          () => factory.create(type).evaluate(const _ForeignInput()),
          throwsA(isA<ValidationFailure>()),
        );
      });
    }
  });

  group('named boundary cases', () {
    test('Recall: the deadline is a closed boundary at exactly 20s', () {
      final recall = factory.create(StudyModeType.recall);
      // Exactly at threshold → a valid timeout.
      final atDeadline = recall.evaluate(
        const RecallInput(
          sessionId: 's',
          cardId: 'c',
          roundIndex: 0,
          eventId: 'e',
          revealed: true,
          resolution: RecallResolution.timeout,
          elapsedActiveMs: 20000,
        ),
      );
      expect(atDeadline.outcome, ModeOutcome.wrong);
      expect(atDeadline.reason, ModeOutcomeReason.timeout);
      // One millisecond short → rejected.
      expect(
        () => recall.evaluate(
          const RecallInput(
            sessionId: 's',
            cardId: 'c',
            roundIndex: 0,
            eventId: 'e',
            revealed: true,
            resolution: RecallResolution.timeout,
            elapsedActiveMs: 19999,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Fill: NFC-equivalent spellings compare equal', () {
      final fill = factory.create(StudyModeType.fill);
      // Decomposed "é" (e + combining acute) vs composed accepted answer.
      final evidence = fill.evaluate(
        const FillInput(
          sessionId: 's',
          cardId: 'c',
          roundIndex: 0,
          eventId: 'e',
          rawInput: 'café', // e + combining acute (decomposed)
          acceptedAnswers: <String>['café'], // é precomposed
        ),
      );
      expect(evidence.outcome, ModeOutcome.correct);
    });

    test('Match: pair-id equality wins even when meanings also match', () {
      final match = factory.create(StudyModeType.match);
      final evidence = match.evaluate(
        const MatchInput(
          sessionId: 's',
          cardId: 'c',
          roundIndex: 0,
          eventId: 'e',
          termPairId: 'p1',
          selectedMeaningPairId: 'p1',
          termMeaning: 'run',
          selectedMeaning: 'run',
        ),
      );
      expect(evidence.outcome, ModeOutcome.correct);
      expect(evidence.pairId, 'p1');
    });
  });
}

/// An input of no concrete mode, used to prove each strategy rejects a payload
/// it does not own.
class _ForeignInput implements StudyModeInput {
  const _ForeignInput();

  @override
  StudyModeType get mode => StudyModeType.review;
  @override
  String get sessionId => 's';
  @override
  String get cardId => 'c';
  @override
  int get roundIndex => 0;
  @override
  String get eventId => 'e';
}
