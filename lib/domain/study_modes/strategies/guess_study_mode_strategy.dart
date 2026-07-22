import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// Every Guess question shows exactly this many choices (`guess-card-meaning.md`
/// §1): one correct answer and [kGuessDistractorCount] distractors.
const int kGuessOptionCount = 5;
const int kGuessDistractorCount = 4;

/// One selectable meaning choice in a Guess question. Evaluation is by
/// [choiceId], never by display text (`guess-card-meaning.md` §4).
class GuessOption {
  const GuessOption({
    required this.choiceId,
    required this.meaning,
    required this.sourceCardId,
  });

  final String choiceId;
  final String meaning;

  /// The card this meaning belongs to; a distractor references another card.
  final String sourceCardId;
}

/// Input for one Guess answer (`guess-card-meaning.md`).
class GuessInput implements StudyModeInput {
  const GuessInput({
    required this.sessionId,
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
    required this.options,
    required this.correctChoiceId,
    required this.selectedChoiceId,
  });

  @override
  StudyModeType get mode => StudyModeType.guess;
  @override
  final String sessionId;
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;

  /// The five presented choices.
  final List<GuessOption> options;

  /// The id of the one correct choice.
  final String correctChoiceId;

  /// The id of the choice the learner picked.
  final String selectedChoiceId;
}

/// Guess (WBS 5.5.4; `guess-card-meaning.md`): pick the correct meaning among
/// exactly five choices. A malformed option set (not five choices, a missing or
/// duplicated correct answer, fewer than five distinct normalized meanings, or a
/// distractor drawn from the current card) is a validation error — no evidence,
/// no advance. Otherwise the outcome is a pure id comparison: the selected
/// choice equals the correct choice → `correct`, else `wrong`.
final class GuessStudyModeStrategy
    extends StudyModeStrategyBase<GuessInput, ModeOutcome> {
  const GuessStudyModeStrategy();

  @override
  StudyModeType get mode => StudyModeType.guess;

  @override
  GuessInput validate(StudyModeInput input) {
    if (input is! GuessInput) {
      throw ValidationFailure(field: 'input', code: 'mode-mismatch');
    }
    final options = input.options;
    if (options.length != kGuessOptionCount) {
      throw ValidationFailure(field: 'options', code: 'not-five-options');
    }
    final choiceIds = options.map((o) => o.choiceId).toSet();
    if (choiceIds.length != kGuessOptionCount) {
      throw ValidationFailure(field: 'options', code: 'duplicate-choice-id');
    }
    final correctCount = options
        .where((o) => o.choiceId == input.correctChoiceId)
        .length;
    if (correctCount != 1) {
      throw ValidationFailure(
        field: 'correctChoiceId',
        code: 'not-exactly-one',
      );
    }
    final distinctMeanings = options
        .map((o) => StringUtils.comparisonKey(o.meaning))
        .toSet();
    if (distinctMeanings.length != kGuessOptionCount) {
      throw ValidationFailure(field: 'options', code: 'meanings-not-distinct');
    }
    final distractorFromCurrentCard = options.any(
      (o) =>
          o.choiceId != input.correctChoiceId && o.sourceCardId == input.cardId,
    );
    if (distractorFromCurrentCard) {
      throw ValidationFailure(field: 'options', code: 'distractor-is-current');
    }
    if (!choiceIds.contains(input.selectedChoiceId)) {
      throw ValidationFailure(field: 'selectedChoiceId', code: 'not-an-option');
    }
    return input;
  }

  @override
  ModeOutcome assess(GuessInput input) {
    return input.selectedChoiceId == input.correctChoiceId
        ? ModeOutcome.correct
        : ModeOutcome.wrong;
  }

  @override
  CanonicalModeEvidence mapCanonicalEvidence(
    GuessInput input,
    ModeOutcome result,
  ) {
    return CanonicalModeEvidence(
      mode: mode,
      outcome: result,
      cardId: input.cardId,
      roundIndex: input.roundIndex,
      eventId: input.eventId,
      mappingVersion: 1,
    );
  }
}
