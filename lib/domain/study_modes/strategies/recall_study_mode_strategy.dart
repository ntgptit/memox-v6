import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The active-time budget before a Recall card auto-reveals and times out
/// (`recall-and-self-grade.md` §1, `RECALL_RESPONSE_TIMEOUT_SECONDS`).
const int kRecallTimeoutSeconds = 20;

/// How a Recall card resolved. `remembered`/`forgot` are presentation labels;
/// `timeout` is the system deadline event. None of these persist — they map to
/// canonical outcomes (`recall-and-self-grade.md` §1).
enum RecallResolution { remembered, forgot, timeout }

/// Input for one Recall resolution (`recall-and-self-grade.md`).
class RecallInput implements StudyModeInput {
  const RecallInput({
    required this.sessionId,
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
    required this.revealed,
    required this.resolution,
    required this.elapsedActiveMs,
    this.timeoutThresholdSeconds = kRecallTimeoutSeconds,
  });

  @override
  StudyModeType get mode => StudyModeType.recall;
  @override
  final String sessionId;
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;

  /// Whether the answer had been revealed when this resolution occurred.
  final bool revealed;

  /// The presentation resolution to map.
  final RecallResolution resolution;

  /// Validated active interaction time elapsed (loading excluded).
  final int elapsedActiveMs;

  /// The deadline in seconds; v1 supports only [kRecallTimeoutSeconds].
  final int timeoutThresholdSeconds;
}

/// Recall (WBS 5.5.4; `recall-and-self-grade.md`): the learner self-grades after
/// revealing, or the 20-second deadline times out. Mapping is deterministic —
/// `Remembered → correct`, `Forgot → wrong`, `timeout → wrong(reason=timeout)`.
/// A self-grade before reveal, or a timeout that has not truly reached the
/// validated active-time deadline, is a validation error (no evidence).
final class RecallStudyModeStrategy
    extends
        StudyModeStrategyBase<
          RecallInput,
          ({ModeOutcome outcome, ModeOutcomeReason? reason})
        > {
  const RecallStudyModeStrategy();

  @override
  StudyModeType get mode => StudyModeType.recall;

  @override
  RecallInput validate(StudyModeInput input) {
    if (input is! RecallInput) {
      throw ValidationFailure(field: 'input', code: 'mode-mismatch');
    }
    if (input.timeoutThresholdSeconds != kRecallTimeoutSeconds) {
      throw ValidationFailure(
        field: 'timeoutThresholdSeconds',
        code: 'unsupported',
      );
    }
    final isSelfGrade =
        input.resolution == RecallResolution.remembered ||
        input.resolution == RecallResolution.forgot;
    if (isSelfGrade && !input.revealed) {
      throw ValidationFailure(field: 'resolution', code: 'grade-before-reveal');
    }
    if (input.resolution == RecallResolution.timeout &&
        input.elapsedActiveMs < input.timeoutThresholdSeconds * 1000) {
      throw ValidationFailure(
        field: 'resolution',
        code: 'timeout-before-deadline',
      );
    }
    return input;
  }

  @override
  ({ModeOutcome outcome, ModeOutcomeReason? reason}) assess(RecallInput input) {
    if (input.resolution == RecallResolution.remembered) {
      return (outcome: ModeOutcome.correct, reason: null);
    }
    if (input.resolution == RecallResolution.forgot) {
      return (outcome: ModeOutcome.wrong, reason: null);
    }
    return (outcome: ModeOutcome.wrong, reason: ModeOutcomeReason.timeout);
  }

  @override
  CanonicalModeEvidence mapCanonicalEvidence(
    RecallInput input,
    ({ModeOutcome outcome, ModeOutcomeReason? reason}) result,
  ) {
    return CanonicalModeEvidence(
      mode: mode,
      outcome: result.outcome,
      cardId: input.cardId,
      roundIndex: input.roundIndex,
      eventId: input.eventId,
      mappingVersion: 1,
      reason: result.reason,
    );
  }
}
