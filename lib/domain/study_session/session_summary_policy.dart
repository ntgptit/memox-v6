import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_session/session_terminal_grade_policy.dart';

/// The committed result of a finished session, derived only from persisted
/// evidence (WBS 5.6.13; `finalize-study-session.md` §5). Counts are per card by
/// terminal grade, so a card that appeared in several mastery rounds is counted
/// once and stage failures are never double-counted.
class StudySessionSummary {
  const StudySessionSummary({
    required this.reviewedCount,
    required this.correctCount,
    required this.missedCardIds,
  });

  /// Distinct cards that reached a terminal grade (correct + missed).
  final int reviewedCount;

  /// Cards whose terminal grade is `correct`.
  final int correctCount;

  /// Cards whose terminal grade is `wrong` (sticky lapse), in first-seen order —
  /// the stable set the `Review missed` branch relearns.
  final List<String> missedCardIds;

  int get missedCount => missedCardIds.length;
}

/// Builds a [StudySessionSummary] from a session's committed mode outcomes
/// (WBS 5.6.13; `finalize-study-session.md` §5). Pure: it composes
/// [SessionTerminalGradePolicy] for the one-grade-per-card aggregation and reads
/// no repository. The missed list uses terminal card outcomes, not per-stage
/// failures, so a card is never double-counted across rounds.
class SessionSummaryPolicy {
  const SessionSummaryPolicy({
    SessionTerminalGradePolicy gradePolicy = const SessionTerminalGradePolicy(),
  }) : _gradePolicy = gradePolicy;

  final SessionTerminalGradePolicy _gradePolicy;

  StudySessionSummary summarize(Iterable<CardOutcome> outcomes) {
    final grades = _gradePolicy.gradesByCard(outcomes);

    // Missed cards in first-seen order for a stable, study-ordered display.
    final seen = <String>{};
    final missed = <String>[];
    for (final outcome in outcomes) {
      if (seen.add(outcome.cardId) &&
          grades[outcome.cardId] == SrsGrade.wrong) {
        missed.add(outcome.cardId);
      }
    }

    final correct = grades.values
        .where((grade) => grade == SrsGrade.correct)
        .length;

    return StudySessionSummary(
      reviewedCount: grades.length,
      correctCount: correct,
      missedCardIds: missed,
    );
  }
}
