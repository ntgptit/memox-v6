import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The mandatory construction boundary that resolves a [StudyModeType] to its
/// one pure strategy (WBS 5.5.5; factory-di-architecture §2). Callers depend
/// only on this — they never switch on the mode or build strategies themselves.
///
/// It is pure domain: it selects no session plan, reads no database and
/// persists nothing. Registration is validated at construction — every mode
/// present exactly once — so a missing or duplicate strategy fails fast with a
/// typed failure before any session can start, and [create] is total.
class StudyModeFactory {
  /// Builds a factory from an explicit strategy list (used by tests to inject
  /// fakes). Throws a typed failure if a mode is registered twice or any mode
  /// is missing.
  StudyModeFactory(List<StudyModeStrategy> strategies)
    : _byMode = _index(strategies);

  /// The production factory with all six concrete strategies.
  factory StudyModeFactory.standard() =>
      StudyModeFactory(const <StudyModeStrategy>[
        ReviewStudyModeStrategy(),
        MatchStudyModeStrategy(),
        GuessStudyModeStrategy(),
        RecallStudyModeStrategy(),
        FillStudyModeStrategy(),
        SrsBinaryReviewStudyModeStrategy(),
      ]);

  final Map<StudyModeType, StudyModeStrategy> _byMode;

  /// The strategy for [type]. Total: construction guarantees every mode is
  /// registered, so this always returns a strategy.
  StudyModeStrategy create(StudyModeType type) {
    final strategy = _byMode[type];
    if (strategy == null) {
      throw ValidationFailure(field: 'studyMode', code: 'missing-strategy');
    }
    return strategy;
  }

  static Map<StudyModeType, StudyModeStrategy> _index(
    List<StudyModeStrategy> strategies,
  ) {
    final byMode = <StudyModeType, StudyModeStrategy>{};
    for (final strategy in strategies) {
      if (byMode.containsKey(strategy.mode)) {
        throw ValidationFailure(field: 'studyMode', code: 'duplicate-strategy');
      }
      byMode[strategy.mode] = strategy;
    }
    for (final type in StudyModeType.values) {
      if (!byMode.containsKey(type)) {
        throw ValidationFailure(field: 'studyMode', code: 'missing-strategy');
      }
    }
    return byMode;
  }
}
