import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// WBS 5.5.5 — the factory resolves every mode to exactly one strategy and
/// fails fast on a missing or duplicate registration (factory-di-architecture
/// §§2,5).
void main() {
  final expectedTypes = <StudyModeType, Type>{
    StudyModeType.review: ReviewStudyModeStrategy,
    StudyModeType.match: MatchStudyModeStrategy,
    StudyModeType.guess: GuessStudyModeStrategy,
    StudyModeType.recall: RecallStudyModeStrategy,
    StudyModeType.fill: FillStudyModeStrategy,
    StudyModeType.srsBinaryReview: SrsBinaryReviewStudyModeStrategy,
  };

  test('the standard factory resolves each mode to its concrete strategy', () {
    final factory = StudyModeFactory.standard();
    for (final type in StudyModeType.values) {
      final strategy = factory.create(type);
      expect(strategy.mode, type);
      expect(strategy.runtimeType, expectedTypes[type]);
    }
  });

  test('resolution is stable — the same instance every call', () {
    final factory = StudyModeFactory.standard();
    expect(
      identical(
        factory.create(StudyModeType.guess),
        factory.create(StudyModeType.guess),
      ),
      isTrue,
    );
  });

  test('a missing strategy fails fast at construction', () {
    final incomplete = <StudyModeStrategy>[
      const ReviewStudyModeStrategy(),
      const MatchStudyModeStrategy(),
      // guess/recall/fill/srsBinaryReview missing.
    ];
    expect(
      () => StudyModeFactory(incomplete),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.code,
          'code',
          'missing-strategy',
        ),
      ),
    );
  });

  test('a duplicate registration fails fast at construction', () {
    final duplicated = <StudyModeStrategy>[
      const ReviewStudyModeStrategy(),
      const ReviewStudyModeStrategy(), // duplicate mode
      const MatchStudyModeStrategy(),
      const GuessStudyModeStrategy(),
      const RecallStudyModeStrategy(),
      const FillStudyModeStrategy(),
      const SrsBinaryReviewStudyModeStrategy(),
    ];
    expect(
      () => StudyModeFactory(duplicated),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.code,
          'code',
          'duplicate-strategy',
        ),
      ),
    );
  });
}
