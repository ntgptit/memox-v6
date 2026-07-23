import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The self-grade a learner gives on a Due Review / Relearn card. Presentation
/// labels only — never a persisted value (`srs-binary-review.md` §1).
enum SrsBinaryAction { remembered, relearn }

/// Input for one SRS Binary Review self-grade (`srs-binary-review.md`).
class SrsBinaryReviewInput implements StudyModeInput {
  const SrsBinaryReviewInput({
    required this.sessionId,
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
    required this.action,
  });

  @override
  StudyModeType get mode => StudyModeType.srsBinaryReview;
  @override
  final String sessionId;
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;

  /// The learner's self-grade.
  final SrsBinaryAction action;
}

/// SRS Binary Review (WBS 5.5.4; `srs-binary-review.md`): the session-only mode
/// for Due Review and the Relearn fallback. It shows term + meaning and maps a
/// binary self-grade deterministically — `Remembered → correct`,
/// `Relearn → wrong` — with no timer, hint or time inference.
final class SrsBinaryReviewStudyModeStrategy
    extends StudyModeStrategyBase<SrsBinaryReviewInput, ModeOutcome> {
  const SrsBinaryReviewStudyModeStrategy();

  @override
  StudyModeType get mode => StudyModeType.srsBinaryReview;

  @override
  SrsBinaryReviewInput validate(StudyModeInput input) {
    if (input is! SrsBinaryReviewInput) {
      throw ValidationFailure(field: 'input', code: 'mode-mismatch');
    }
    return input;
  }

  @override
  ModeOutcome assess(SrsBinaryReviewInput input) {
    return input.action == SrsBinaryAction.remembered
        ? ModeOutcome.correct
        : ModeOutcome.wrong;
  }

  @override
  CanonicalModeEvidence mapCanonicalEvidence(
    SrsBinaryReviewInput input,
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
