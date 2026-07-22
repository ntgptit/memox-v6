import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// Input for one Match pair resolution (SM-MATCH-v1). The learner pairs a term
/// tile with a meaning tile; classification is by pair id, with normalized
/// meanings only distinguishing `wrong` from `almost`.
class MatchInput implements StudyModeInput {
  const MatchInput({
    required this.sessionId,
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
    required this.termPairId,
    required this.selectedMeaningPairId,
    required this.termMeaning,
    required this.selectedMeaning,
  });

  @override
  StudyModeType get mode => StudyModeType.match;
  @override
  final String sessionId;

  /// The term-owner card (the mastery-round membership key).
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;

  /// The pair id of the selected term tile.
  final String termPairId;

  /// The pair id of the selected meaning tile.
  final String selectedMeaningPairId;

  /// The term's own correct meaning.
  final String termMeaning;

  /// The meaning shown on the selected tile.
  final String selectedMeaning;
}

/// Match (WBS 5.5.4; SM-MATCH-v1): pair a term with a meaning. Classification is
/// pure id/text, never gesture, distance or time:
/// - the selected meaning's pair id equals the term's → `correct` (SM-MATCH-001);
/// - pair ids differ and the normalized meanings differ → `wrong` (SM-MATCH-002);
/// - pair ids differ but the normalized meanings are equal → `almost` with
///   reason `duplicateNormalizedMeaning` (SM-MATCH-003).
/// A missing or stale tile is an invalid interaction (SM-MATCH-007) — no
/// evidence.
final class MatchStudyModeStrategy
    extends
        StudyModeStrategyBase<
          MatchInput,
          ({ModeOutcome outcome, ModeOutcomeReason? reason})
        > {
  const MatchStudyModeStrategy();

  @override
  StudyModeType get mode => StudyModeType.match;

  @override
  MatchInput validate(StudyModeInput input) {
    if (input is! MatchInput) {
      throw ValidationFailure(field: 'input', code: 'mode-mismatch');
    }
    if (input.termPairId.isEmpty || input.selectedMeaningPairId.isEmpty) {
      throw ValidationFailure(field: 'pair', code: 'missing-tile');
    }
    return input;
  }

  @override
  ({ModeOutcome outcome, ModeOutcomeReason? reason}) assess(MatchInput input) {
    if (input.termPairId == input.selectedMeaningPairId) {
      return (outcome: ModeOutcome.correct, reason: null);
    }
    final sameMeaning =
        StringUtils.comparisonKey(input.termMeaning) ==
        StringUtils.comparisonKey(input.selectedMeaning);
    if (sameMeaning) {
      return (
        outcome: ModeOutcome.almost,
        reason: ModeOutcomeReason.duplicateNormalizedMeaning,
      );
    }
    return (outcome: ModeOutcome.wrong, reason: null);
  }

  @override
  CanonicalModeEvidence mapCanonicalEvidence(
    MatchInput input,
    ({ModeOutcome outcome, ModeOutcomeReason? reason}) result,
  ) {
    return CanonicalModeEvidence(
      mode: mode,
      outcome: result.outcome,
      cardId: input.cardId,
      pairId: input.termPairId,
      roundIndex: input.roundIndex,
      eventId: input.eventId,
      mappingVersion: 1,
      reason: result.reason,
    );
  }
}
