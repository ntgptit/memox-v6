import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';

/// One committed mode outcome for a card in a session (the finalize input:
/// `StudyAttempt.cardId` + its canonical `ModeOutcome`).
typedef CardOutcome = ({String cardId, ModeOutcome outcome});

/// Aggregates a session's committed mode outcomes into exactly one terminal SRS
/// grade per card (WBS 5.6.13; `finalize-study-session.md` §5, SRS Policy v1 §1).
///
/// Pure and order-independent. The rule is **sticky lapse**: any committed
/// `wrong` or `almost` (a Recall timeout commits canonical `wrong`) makes the
/// terminal grade `wrong`, even if a later mastery round answered the card
/// correctly — reaching mastery to end the session never clears the lapse. A
/// card with at least one `correct` and no lapse grades `correct`. Review's
/// ungraded `reviewed` outcome never contributes, so a card seen only in Review
/// (or with no graded outcome) has no terminal grade and is not scheduled here.
///
/// It maps only to the binary [SrsGrade] the scheduler accepts; it never touches
/// box math, timing or persistence (those are [Srs8BoxPolicy] and the repository).
class SessionTerminalGradePolicy {
  const SessionTerminalGradePolicy();

  Map<String, SrsGrade> gradesByCard(Iterable<CardOutcome> outcomes) {
    final lapsed = <String>{};
    final passed = <String>{};
    for (final outcome in outcomes) {
      switch (outcome.outcome) {
        case ModeOutcome.wrong:
        case ModeOutcome.almost:
          lapsed.add(outcome.cardId);
        case ModeOutcome.correct:
          passed.add(outcome.cardId);
        case ModeOutcome.reviewed:
          break;
      }
    }

    return <String, SrsGrade>{
      for (final cardId in <String>{...lapsed, ...passed})
        cardId: lapsed.contains(cardId) ? SrsGrade.wrong : SrsGrade.correct,
    };
  }
}
