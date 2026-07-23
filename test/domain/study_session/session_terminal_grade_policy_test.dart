import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_session/session_terminal_grade_policy.dart';

/// WBS 5.6.13 — the terminal SRS grade a session commits for each card
/// (`finalize-study-session.md` §5, SRS Policy v1 §1).
void main() {
  const policy = SessionTerminalGradePolicy();

  CardOutcome outcome(String cardId, ModeOutcome o) =>
      (cardId: cardId, outcome: o);

  test('a card answered correct throughout grades correct', () {
    final grades = policy.gradesByCard(<CardOutcome>[
      outcome('a', ModeOutcome.reviewed),
      outcome('a', ModeOutcome.correct),
      outcome('a', ModeOutcome.correct),
    ]);
    expect(grades, <String, SrsGrade>{'a': SrsGrade.correct});
  });

  test('any committed wrong makes the terminal grade a sticky wrong', () {
    // Failed in an early round, mastered in a later retry round → still wrong.
    final grades = policy.gradesByCard(<CardOutcome>[
      outcome('a', ModeOutcome.wrong),
      outcome('a', ModeOutcome.correct),
    ]);
    expect(grades, <String, SrsGrade>{'a': SrsGrade.wrong});
  });

  test('the lapse is sticky regardless of outcome order', () {
    final grades = policy.gradesByCard(<CardOutcome>[
      outcome('a', ModeOutcome.correct),
      outcome('a', ModeOutcome.wrong),
    ]);
    expect(grades['a'], SrsGrade.wrong);
  });

  test('an almost is a lapse (SM-MATCH-003) and grades wrong', () {
    final grades = policy.gradesByCard(<CardOutcome>[
      outcome('a', ModeOutcome.correct),
      outcome('a', ModeOutcome.almost),
    ]);
    expect(grades['a'], SrsGrade.wrong);
  });

  test('a card seen only in Review has no terminal grade', () {
    final grades = policy.gradesByCard(<CardOutcome>[
      outcome('a', ModeOutcome.reviewed),
    ]);
    expect(grades.containsKey('a'), isFalse);
  });

  test('grades are independent per card', () {
    final grades = policy.gradesByCard(<CardOutcome>[
      outcome('a', ModeOutcome.correct),
      outcome('b', ModeOutcome.wrong),
      outcome('c', ModeOutcome.reviewed),
      outcome('c', ModeOutcome.correct),
    ]);
    expect(grades, <String, SrsGrade>{
      'a': SrsGrade.correct,
      'b': SrsGrade.wrong,
      'c': SrsGrade.correct,
    });
  });

  test('no outcomes yields no grades', () {
    expect(policy.gradesByCard(const <CardOutcome>[]), isEmpty);
  });
}
