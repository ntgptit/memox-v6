import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// Input for a completed Review browse of one card (`review-cards.md`).
class ReviewInput implements StudyModeInput {
  const ReviewInput({
    required this.sessionId,
    required this.cardId,
    required this.eventId,
    this.roundIndex = 0,
  });

  @override
  StudyModeType get mode => StudyModeType.review;
  @override
  final String sessionId;
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;
}

/// Review (WBS 5.5.4; `review-cards.md`): a quick browse with no right/wrong
/// grade and no mastery round. Completing a card yields the canonical
/// `reviewed` outcome unconditionally.
final class ReviewStudyModeStrategy
    extends StudyModeStrategyBase<ReviewInput, ModeOutcome> {
  const ReviewStudyModeStrategy();

  @override
  StudyModeType get mode => StudyModeType.review;

  @override
  ReviewInput validate(StudyModeInput input) {
    if (input is! ReviewInput) {
      throw ValidationFailure(field: 'input', code: 'mode-mismatch');
    }
    return input;
  }

  @override
  ModeOutcome assess(ReviewInput input) => ModeOutcome.reviewed;

  @override
  CanonicalModeEvidence mapCanonicalEvidence(
    ReviewInput input,
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
