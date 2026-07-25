import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';

/// One committed mode outcome for a card in a session (the finalize input:
/// `StudyAttempt.cardId` + its canonical `ModeOutcome`).
typedef CardOutcome = ({String cardId, ModeOutcome outcome});

/// Aggregates a session's committed mode outcomes into exactly one terminal SRS
/// grade per card (WBS 5.6.13; `finalize-study-session.md` §5, SRS Policy v1 §1).
///
/// This is the *session* half of the fold: it groups committed attempts by card
/// and translates each canonical [ModeOutcome] into the [SrsEvidence] the
/// scheduler reasons about. The sticky-lapse rule itself — any committed
/// `wrong`, `almost` or timeout in any mastery round grading the card `wrong`
/// even when a later retry passes it (SRS8-010) — belongs to
/// [Srs8BoxPolicy.terminalGrade] and is deferred to it rather than restated
/// here, so the two can never drift apart.
///
/// Review's ungraded `reviewed` outcome is not evidence, so it is dropped
/// before folding: a card seen only in Review has no graded evidence, the
/// policy answers `null`, and the card is not scheduled.
///
/// Pure and order-independent. It never touches box math, timing or persistence.
class SessionTerminalGradePolicy {
  const SessionTerminalGradePolicy();

  Map<String, SrsGrade> gradesByCard(Iterable<CardOutcome> outcomes) {
    final evidenceByCard = <String, List<SrsEvidence>>{};
    for (final outcome in outcomes) {
      final evidence = _evidenceOf(outcome.outcome);
      if (evidence == null) continue;
      evidenceByCard
          .putIfAbsent(outcome.cardId, () => <SrsEvidence>[])
          .add(evidence);
    }

    return <String, SrsGrade>{
      for (final entry in evidenceByCard.entries)
        entry.key: ?Srs8BoxPolicy.terminalGrade(entry.value),
    };
  }

  /// `null` for an outcome that is not graded evidence.
  ///
  /// A Recall timeout commits the canonical `wrong` outcome — the timeout
  /// reason is not carried on [CardOutcome] — so it folds through
  /// [SrsEvidence.wrong]. Both are lapses, so the terminal grade is the same
  /// either way.
  SrsEvidence? _evidenceOf(ModeOutcome outcome) => switch (outcome) {
    ModeOutcome.correct => SrsEvidence.passed,
    ModeOutcome.wrong => SrsEvidence.wrong,
    ModeOutcome.almost => SrsEvidence.almost,
    ModeOutcome.reviewed => null,
  };
}
