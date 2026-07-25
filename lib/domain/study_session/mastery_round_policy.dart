import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';

/// The pure round-completion rule the answer boundary consults before advancing
/// (WBS 5.6.10/5.6.11 domain part; `answer-study-stage.md` §§5,11,13, Study Mode
/// README mastery-round contract, `map-mode-outcome.md` §3).
///
/// It only classifies a round from its committed canonical evidence — it
/// persists nothing, builds no next round order and schedules no SRS. The
/// Session owns deduping the failed set and deciding the next round; this policy
/// gives it the deterministic answer.
class MasteryRoundPolicy {
  const MasteryRoundPolicy();

  /// The deduped next-round failed set from a round's committed [roundEvidence],
  /// in first-failure order. A card is failed if it has **any** non-passing
  /// outcome in the round (`wrong`, or Match's `almost`); a later passing
  /// outcome on the same card does **not** clear it, and a repeated failure adds
  /// no second entry (`answer-study-stage.md` §5).
  List<String> nextRoundFailedCardIds(
    List<CanonicalModeEvidence> roundEvidence,
  ) {
    final failed = <String>{};
    final ordered = <String>[];
    for (final evidence in roundEvidence) {
      if (!_isNonPassing(evidence.outcome)) continue;
      if (failed.add(evidence.cardId)) ordered.add(evidence.cardId);
    }
    return ordered;
  }

  /// Whether the mode may advance: a graded mode completes only when the round
  /// just finished has an empty failed set (`answer-study-stage.md` §11). Review
  /// has no non-passing outcome, so it always completes once browsed.
  bool isModeComplete(List<String> nextRoundFailedCardIds) =>
      nextRoundFailedCardIds.isEmpty;

  /// A single canonical outcome is non-passing when it is `wrong` or `almost`
  /// (`map-mode-outcome.md` §3). `reviewed` and `correct` are passing.
  bool _isNonPassing(ModeOutcome outcome) =>
      outcome == ModeOutcome.wrong || outcome == ModeOutcome.almost;
}
