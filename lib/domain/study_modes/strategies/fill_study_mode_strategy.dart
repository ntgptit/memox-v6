import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The only comparison policy version this strategy supports (SM-FILL-v1).
const String kFillComparePolicyV1 = 'fill-compare-v1';

/// Input for one Fill submission (SM-FILL-v1).
class FillInput implements StudyModeInput {
  const FillInput({
    required this.sessionId,
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
    required this.rawInput,
    required this.acceptedAnswers,
    this.comparisonPolicyId = kFillComparePolicyV1,
    this.imeComposing = false,
    this.hintUsed = false,
  });

  @override
  StudyModeType get mode => StudyModeType.fill;
  @override
  final String sessionId;
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;

  /// The learner's raw typed answer.
  final String rawInput;

  /// The accepted answers from the immutable card snapshot: the primary meaning
  /// plus any explicit accepted alternatives (never a search index).
  final List<String> acceptedAnswers;

  /// The comparison policy version to apply.
  final String comparisonPolicyId;

  /// Whether an IME composition is still uncommitted.
  final bool imeComposing;

  /// Whether the learner revealed a hint (audit only; does not change grading).
  final bool hintUsed;
}

/// Fill (WBS 5.5.4; SM-FILL-v1): the learner types the answer, compared under
/// `fill-compare-v1` (NFC → case fold → trim + collapse whitespace, diacritics
/// and word order preserved; no fuzzy match). A normalized exact match against
/// the primary or an accepted alternative → `correct`, else `wrong`. Blank
/// input, an uncommitted IME composition and an unsupported policy version are
/// validation errors — no evidence.
///
/// Extended audit fields the spec persists (matched alternative id, hint-used
/// flag, normalized input) are the Session evidence-writer's concern (5.6);
/// this strategy owns the canonical classification.
final class FillStudyModeStrategy
    extends StudyModeStrategyBase<FillInput, ModeOutcome> {
  const FillStudyModeStrategy();

  @override
  StudyModeType get mode => StudyModeType.fill;

  @override
  FillInput validate(StudyModeInput input) {
    if (input is! FillInput) {
      throw ValidationFailure(field: 'input', code: 'mode-mismatch');
    }
    if (input.comparisonPolicyId != kFillComparePolicyV1) {
      throw ValidationFailure(field: 'comparisonPolicyId', code: 'unsupported');
    }
    if (input.imeComposing) {
      throw ValidationFailure(field: 'input', code: 'ime-composing');
    }
    if (StringUtils.collapsedWhitespace(input.rawInput).isEmpty) {
      throw ValidationFailure(field: 'answer', code: 'required');
    }
    return input;
  }

  @override
  ModeOutcome assess(FillInput input) {
    final key = StringUtils.comparisonKey(input.rawInput);
    final matches = input.acceptedAnswers.any(
      (answer) => StringUtils.comparisonKey(answer) == key,
    );
    return matches ? ModeOutcome.correct : ModeOutcome.wrong;
  }

  @override
  CanonicalModeEvidence mapCanonicalEvidence(
    FillInput input,
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
