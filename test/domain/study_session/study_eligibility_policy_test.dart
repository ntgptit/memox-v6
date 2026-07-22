import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_eligibility_policy.dart';

/// WBS 5.6.1 — start eligibility per session type (ST-SESSION-TYPE-v1;
/// `start-study-session.md` §5).
void main() {
  const policy = StudyEligibilityPolicy();

  StartEligibility resolve({
    required SessionType type,
    StudyModeType? mode,
    int eligible = 6,
    int due = 6,
    int meanings = 6,
  }) => policy.resolve(
    type: type,
    selectedMode: mode,
    eligibleCardCount: eligible,
    dueCardCount: due,
    distinctMeaningCount: meanings,
  );

  test('the Guess pool needs at least five distinct meanings', () {
    expect(policy.isGuessPoolSufficient(4), isFalse);
    expect(policy.isGuessPoolSufficient(5), isTrue);
  });

  group('dueReview', () {
    test('ST-TYPE-005: a non-empty due queue starts', () {
      expect(resolve(type: SessionType.dueReview, due: 1).canStart, isTrue);
    });
    test('ST-TYPE-006: an empty due queue is caught-up, not empty', () {
      final r = resolve(type: SessionType.dueReview, due: 0);
      expect(r.blockReason, StartBlockReason.dueCaughtUp);
    });
  });

  group('practice', () {
    test('ST-TYPE-004: no selected mode blocks', () {
      final r = resolve(type: SessionType.practice);
      expect(r.blockReason, StartBlockReason.practiceModeNotSelected);
    });
    test('ST-TYPE-003: a selected non-Guess mode with cards starts', () {
      expect(
        resolve(type: SessionType.practice, mode: StudyModeType.match).canStart,
        isTrue,
      );
    });
    test('ST-TYPE-011: a Guess practice needs the distinct-meaning pool', () {
      expect(
        resolve(
          type: SessionType.practice,
          mode: StudyModeType.guess,
          meanings: 4,
        ).blockReason,
        StartBlockReason.guessPoolInsufficient,
      );
      expect(
        resolve(
          type: SessionType.practice,
          mode: StudyModeType.guess,
          meanings: 5,
        ).canStart,
        isTrue,
      );
    });
    test('an empty scope blocks', () {
      expect(
        resolve(
          type: SessionType.practice,
          mode: StudyModeType.fill,
          eligible: 0,
        ).blockReason,
        StartBlockReason.scopeEmpty,
      );
    });
  });

  group('newLearning', () {
    test('ST-TYPE-001: cards plus a Guess pool start', () {
      expect(resolve(type: SessionType.newLearning).canStart, isTrue);
    });
    test('ST-TYPE-011: a short Guess pool blocks (no downgrade)', () {
      expect(
        resolve(type: SessionType.newLearning, meanings: 4).blockReason,
        StartBlockReason.guessPoolInsufficient,
      );
    });
    test('no new cards blocks as empty scope', () {
      expect(
        resolve(type: SessionType.newLearning, eligible: 0).blockReason,
        StartBlockReason.scopeEmpty,
      );
    });
  });

  group('relearn', () {
    test('ST-TYPE-016: a short Guess pool still starts (binary fallback)', () {
      expect(resolve(type: SessionType.relearn, meanings: 2).canStart, isTrue);
    });
    test('an empty missed set blocks', () {
      expect(
        resolve(type: SessionType.relearn, eligible: 0).blockReason,
        StartBlockReason.scopeEmpty,
      );
    });
  });
}
