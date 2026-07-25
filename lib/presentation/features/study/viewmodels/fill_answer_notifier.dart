import 'package:memox_v6/app/di/study_mode_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fill_answer_notifier.g.dart';

/// The graded outcome of the current Fill card, or `null` while still typing
/// (WBS 5.6.9; `fill-card-answer.md`). Grading is a pure preview through the
/// mode factory — it never commits; the answer command commits on Continue.
/// Keyed by `cardId` so it resets when the round advances to the next card.
@riverpod
class FillFeedback extends _$FillFeedback {
  @override
  ModeOutcome? build(String cardId) => null;

  /// Compares the typed answer under `fill-compare-v1` (SM-FILL-v1) via the
  /// factory's pure `evaluate`. A validation failure (blank / uncommitted IME)
  /// leaves the learner in the typing state without creating evidence.
  void grade(FillInput input) {
    try {
      final evidence = ref
          .read(studyModeFactoryProvider)
          .create(StudyModeType.fill)
          .evaluate(input);
      state = evidence.outcome;
    } on ValidationFailure {
      state = null;
    }
  }

  void reset() => state = null;
}

/// Whether the learner revealed the hint for the current Fill card (audit only;
/// it never changes grading — `fill-card-answer.md` §1). Keyed by `cardId`.
@riverpod
class FillHint extends _$FillHint {
  @override
  bool build(String cardId) => false;

  void reveal() => state = true;
}
