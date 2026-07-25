import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/random/deterministic_random.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/study_modes/round_order_policy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// One card in the Guess candidate pool: its id and its display meaning.
class GuessCandidate {
  const GuessCandidate({required this.cardId, required this.meaning});

  final String cardId;
  final String meaning;
}

/// A built Guess question: the ordered options and which choice is correct.
class GuessQuestion {
  const GuessQuestion({required this.options, required this.correctChoiceId});

  final List<GuessOption> options;
  final String correctChoiceId;
}

/// Builds a Guess question deterministically (WBS 5.6.7; `guess-card-meaning.md`
/// §§1,4). Pure domain: given the target card and the session's stable candidate
/// pool, it produces exactly [kGuessOptionCount] options — one correct (the
/// target's meaning) and [kGuessDistractorCount] distractors drawn from *other*
/// cards, all with distinct normalized meanings and none equal to the correct.
///
/// Distractor selection and option order are seeded shuffles keyed on the
/// session/card/round, so a Resume rebuilds the identical five options in the
/// identical order. A pool without enough distinct meanings fails closed with a
/// typed [ValidationFailure] — there is no reduced-option-count fallback
/// (ST-TYPE-011).
class GuessQuestionBuilder {
  const GuessQuestionBuilder();

  GuessQuestion build({
    required String sessionId,
    required int roundIndex,
    required GuessCandidate target,
    required List<GuessCandidate> pool,
  }) {
    final correctKey = StringUtils.comparisonKey(target.meaning);

    // Distractors: other cards whose normalized meaning is distinct and differs
    // from the correct answer (dedupe by normalized meaning).
    final seenKeys = <String>{correctKey};
    final distractorPool = <GuessCandidate>[];
    for (final candidate in pool) {
      if (candidate.cardId == target.cardId) continue;
      if (seenKeys.add(StringUtils.comparisonKey(candidate.meaning))) {
        distractorPool.add(candidate);
      }
    }
    if (distractorPool.length < kGuessDistractorCount) {
      throw ValidationFailure(
        field: 'guessPool',
        code: 'insufficient-distinct-meanings',
      );
    }

    final distractors = deterministicShuffle(
      distractorPool,
      roundOrderSeed(
        sessionId: sessionId,
        modeId: 'guess-distractors-${target.cardId}',
        roundIndex: roundIndex,
      ),
    ).take(kGuessDistractorCount);

    final options = <GuessOption>[
      GuessOption(
        choiceId: target.cardId,
        meaning: target.meaning,
        sourceCardId: target.cardId,
      ),
      for (final distractor in distractors)
        GuessOption(
          choiceId: distractor.cardId,
          meaning: distractor.meaning,
          sourceCardId: distractor.cardId,
        ),
    ];

    final ordered = deterministicShuffle(
      options,
      roundOrderSeed(
        sessionId: sessionId,
        modeId: '${StudyModeType.guess.id}-options-${target.cardId}',
        roundIndex: roundIndex,
      ),
    );

    return GuessQuestion(options: ordered, correctChoiceId: target.cardId);
  }
}
