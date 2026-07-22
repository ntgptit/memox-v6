import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/mastery_round_policy.dart';

/// WBS 5.6.10/5.6.11 (domain part) — round completion / failed-set rule
/// (`answer-study-stage.md` §§5,11).
void main() {
  const policy = MasteryRoundPolicy();

  CanonicalModeEvidence ev(
    String cardId,
    ModeOutcome outcome, {
    StudyModeType mode = StudyModeType.guess,
  }) => CanonicalModeEvidence(
    mode: mode,
    outcome: outcome,
    cardId: cardId,
    roundIndex: 0,
    eventId: '$cardId-${outcome.id}',
    mappingVersion: 1,
  );

  test('an all-correct round has an empty failed set and completes', () {
    final failed = policy.nextRoundFailedCardIds(<CanonicalModeEvidence>[
      ev('a', ModeOutcome.correct),
      ev('b', ModeOutcome.correct),
    ]);
    expect(failed, isEmpty);
    expect(policy.isModeComplete(failed), isTrue);
  });

  test('a wrong outcome fails its card and blocks completion', () {
    final failed = policy.nextRoundFailedCardIds(<CanonicalModeEvidence>[
      ev('a', ModeOutcome.correct),
      ev('b', ModeOutcome.wrong),
    ]);
    expect(failed, <String>['b']);
    expect(policy.isModeComplete(failed), isFalse);
  });

  test('a later correct does not clear an already-failed card', () {
    final failed = policy.nextRoundFailedCardIds(<CanonicalModeEvidence>[
      ev('a', ModeOutcome.wrong),
      ev('a', ModeOutcome.correct), // retry passes, but the lapse stays
    ]);
    expect(failed, <String>['a']);
  });

  test('a repeated failure adds only one entry, in first-failure order', () {
    final failed = policy.nextRoundFailedCardIds(<CanonicalModeEvidence>[
      ev('b', ModeOutcome.wrong),
      ev('a', ModeOutcome.wrong),
      ev('b', ModeOutcome.wrong),
    ]);
    expect(failed, <String>['b', 'a']);
  });

  test('Match almost counts as non-passing', () {
    final failed = policy.nextRoundFailedCardIds(<CanonicalModeEvidence>[
      ev('a', ModeOutcome.almost, mode: StudyModeType.match),
    ]);
    expect(failed, <String>['a']);
  });

  test('a reviewed browse never contributes to the failed set', () {
    final failed = policy.nextRoundFailedCardIds(<CanonicalModeEvidence>[
      ev('a', ModeOutcome.reviewed, mode: StudyModeType.review),
      ev('b', ModeOutcome.reviewed, mode: StudyModeType.review),
    ]);
    expect(failed, isEmpty);
    expect(policy.isModeComplete(failed), isTrue);
  });
}
