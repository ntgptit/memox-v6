import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_mode_plan.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';

/// WBS 5.6.2 (domain part) — mode-plan resolution per session type
/// (ST-SESSION-TYPE-v1; `start-study-session.md` §7).
void main() {
  const resolver = SessionModePlanResolver();

  test(
    'ST-TYPE-001: newLearning is the fixed five-mode plan, SRS-scheduling',
    () {
      final plan = resolver.resolve(type: SessionType.newLearning);
      expect(plan.planId, kNewLearningPlanV1);
      expect(plan.stages, <StudyModeType>[
        StudyModeType.review,
        StudyModeType.match,
        StudyModeType.guess,
        StudyModeType.recall,
        StudyModeType.fill,
      ]);
      expect(plan.scheduleSrs, isTrue);
    },
  );

  test('ST-TYPE-003: practice is the one selected mode, no SRS scheduling', () {
    final plan = resolver.resolve(
      type: SessionType.practice,
      selectedMode: StudyModeType.fill,
    );
    expect(plan.planId, kPracticePlanV1);
    expect(plan.stages, <StudyModeType>[StudyModeType.fill]);
    expect(plan.scheduleSrs, isFalse);
  });

  test('practice without a selected mode is a typed failure', () {
    expect(
      () => resolver.resolve(type: SessionType.practice),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('ST-TYPE-005: dueReview is the binary plan, SRS-scheduling', () {
    final plan = resolver.resolve(type: SessionType.dueReview);
    expect(plan.planId, kDueReviewBinaryPlanV1);
    expect(plan.stages, <StudyModeType>[StudyModeType.srsBinaryReview]);
    expect(plan.scheduleSrs, isTrue);
  });

  group('relearn (ST-TYPE-015/016)', () {
    test('a sufficient Guess pool resolves the Guess plan', () {
      final plan = resolver.resolve(
        type: SessionType.relearn,
        guessPoolSufficient: true,
      );
      expect(plan.planId, kRelearnGuessPlanV1);
      expect(plan.stages, <StudyModeType>[StudyModeType.guess]);
      expect(plan.scheduleSrs, isTrue);
    });

    test('a short Guess pool falls back to the binary plan', () {
      final plan = resolver.resolve(
        type: SessionType.relearn,
        guessPoolSufficient: false,
      );
      expect(plan.planId, kRelearnBinaryPlanV1);
      expect(plan.stages, <StudyModeType>[StudyModeType.srsBinaryReview]);
      expect(plan.scheduleSrs, isTrue);
    });
  });
}
