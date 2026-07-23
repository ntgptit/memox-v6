import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/domain/study_session/session_terminal_grade_policy.dart';

/// WBS 5.6.13 — the committed session summary (`finalize-study-session.md` §5):
/// counts derive from persisted evidence, one terminal grade per card.
void main() {
  const policy = SessionSummaryPolicy();

  CardOutcome outcome(String cardId, ModeOutcome o) =>
      (cardId: cardId, outcome: o);

  test('all-correct cards summarize to a clean result', () {
    final summary = policy.summarize(<CardOutcome>[
      outcome('a', ModeOutcome.reviewed),
      outcome('a', ModeOutcome.correct),
      outcome('b', ModeOutcome.correct),
    ]);
    expect(summary.reviewedCount, 2);
    expect(summary.correctCount, 2);
    expect(summary.missedCount, 0);
    expect(summary.missedCardIds, isEmpty);
  });

  test('a card is counted once by terminal grade across mastery rounds', () {
    // 'a' fails then passes a retry round → one missed card, not two attempts.
    final summary = policy.summarize(<CardOutcome>[
      outcome('a', ModeOutcome.wrong),
      outcome('a', ModeOutcome.correct),
    ]);
    expect(summary.reviewedCount, 1);
    expect(summary.correctCount, 0);
    expect(summary.missedCardIds, <String>['a']);
  });

  test('missed cards are listed in first-seen order', () {
    final summary = policy.summarize(<CardOutcome>[
      outcome('a', ModeOutcome.correct),
      outcome('b', ModeOutcome.wrong),
      outcome('c', ModeOutcome.wrong),
      outcome('b', ModeOutcome.correct),
    ]);
    expect(summary.reviewedCount, 3);
    expect(summary.correctCount, 1);
    expect(summary.missedCardIds, <String>['b', 'c']);
  });

  test('a Review-only card is not counted', () {
    final summary = policy.summarize(<CardOutcome>[
      outcome('a', ModeOutcome.reviewed),
    ]);
    expect(summary.reviewedCount, 0);
    expect(summary.correctCount, 0);
    expect(summary.missedCount, 0);
  });

  test('an empty session summarizes to zeros', () {
    final summary = policy.summarize(const <CardOutcome>[]);
    expect(summary.reviewedCount, 0);
    expect(summary.correctCount, 0);
    expect(summary.missedCardIds, isEmpty);
  });
}
