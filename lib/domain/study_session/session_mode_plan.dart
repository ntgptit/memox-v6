import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';

/// Versioned mode-plan ids persisted in a session snapshot
/// (`start-study-session.md` §7). `due-review-binary-v1`, `relearn-guess-v1`
/// and `relearn-binary-v1` are named by the spec; `new-learning-v1` and
/// `practice-v1` follow the same `-v1` convention (the spec fixes their stages,
/// not a string). Changing any plan's shape requires a new id.
const String kNewLearningPlanV1 = 'new-learning-v1';
const String kPracticePlanV1 = 'practice-v1';
const String kDueReviewBinaryPlanV1 = 'due-review-binary-v1';
const String kRelearnGuessPlanV1 = 'relearn-guess-v1';
const String kRelearnBinaryPlanV1 = 'relearn-binary-v1';

/// The frozen new-learning stage order (ST-TYPE-001; `start-study-session.md`
/// §7): Review → Match → Guess → Recall → Fill.
const List<StudyModeType> kNewLearningStages = <StudyModeType>[
  StudyModeType.review,
  StudyModeType.match,
  StudyModeType.guess,
  StudyModeType.recall,
  StudyModeType.fill,
];

/// A resolved, immutable mode plan for a session snapshot: the versioned plan
/// id, its ordered stages and whether terminal grades schedule SRS. Once
/// snapshotted the plan is replayed verbatim on Retry/Resume — never re-resolved
/// (ST-TYPE-018).
class SessionModePlan {
  const SessionModePlan({
    required this.planId,
    required this.stages,
    required this.scheduleSrs,
  });

  final String planId;
  final List<StudyModeType> stages;
  final bool scheduleSrs;
}

/// Resolves the versioned mode plan for a session type (WBS 5.6.2 domain part;
/// ST-SESSION-TYPE-v1, `start-study-session.md` §7). Pure and deterministic:
/// eligibility (5.6.1) has already passed, so this only maps a valid start to
/// its plan; it persists nothing and reads no repository.
class SessionModePlanResolver {
  const SessionModePlanResolver();

  /// [selectedMode] is required for Practice (ST-TYPE-003). [guessPoolSufficient]
  /// chooses the Relearn plan: Guess when the snapshot has the pool, else the
  /// binary fallback (ST-TYPE-015/016).
  SessionModePlan resolve({
    required SessionType type,
    StudyModeType? selectedMode,
    bool guessPoolSufficient = false,
  }) {
    switch (type) {
      case SessionType.newLearning:
        // ST-TYPE-001: the fixed five-mode plan; activation schedules SRS.
        return const SessionModePlan(
          planId: kNewLearningPlanV1,
          stages: kNewLearningStages,
          scheduleSrs: true,
        );

      case SessionType.practice:
        // ST-TYPE-003: exactly one selected mode; no SRS scheduling.
        if (selectedMode == null) {
          throw ValidationFailure(field: 'selectedMode', code: 'required');
        }
        return SessionModePlan(
          planId: kPracticePlanV1,
          stages: <StudyModeType>[selectedMode],
          scheduleSrs: false,
        );

      case SessionType.dueReview:
        // ST-TYPE-005: binary review over the due queue; terminal grades schedule.
        return const SessionModePlan(
          planId: kDueReviewBinaryPlanV1,
          stages: <StudyModeType>[StudyModeType.srsBinaryReview],
          scheduleSrs: true,
        );

      case SessionType.relearn:
        // ST-TYPE-015/016: Guess when the pool is present, else binary fallback.
        if (guessPoolSufficient) {
          return const SessionModePlan(
            planId: kRelearnGuessPlanV1,
            stages: <StudyModeType>[StudyModeType.guess],
            scheduleSrs: true,
          );
        }
        return const SessionModePlan(
          planId: kRelearnBinaryPlanV1,
          stages: <StudyModeType>[StudyModeType.srsBinaryReview],
          scheduleSrs: true,
        );
    }
  }
}
