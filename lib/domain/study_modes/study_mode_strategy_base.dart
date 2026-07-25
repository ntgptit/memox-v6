import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy.dart';

/// The mandatory pure template every concrete Study Mode strategy extends
/// (WBS 5.5.2; factory-di-architecture §3). It fixes the three-step pipeline
///
/// ```text
/// validate(input) → evaluate(validInput) → mapCanonicalEvidence(result)
/// ```
///
/// and nothing else: it writes no Attempt, advances no checkpoint, builds no
/// retry round, performs no navigation and touches no Riverpod or Drift. A
/// subclass owns only the mode-specific rules of the three hooks; it cannot
/// reorder or skip a step. [I] is the mode's typed input, [R] its intermediate
/// evaluation result.
abstract base class StudyModeStrategyBase<I extends StudyModeInput, R>
    implements StudyModeStrategy {
  const StudyModeStrategyBase();

  /// The fixed pipeline. Concrete strategies must not override this — they
  /// implement the three hooks instead.
  @override
  CanonicalModeEvidence evaluate(StudyModeInput input) {
    final validInput = validate(input);
    final result = assess(validInput);
    return mapCanonicalEvidence(validInput, result);
  }

  /// Step 1 — narrow and validate the raw input to this mode's typed input,
  /// throwing a typed failure for an unsupported or mismatched payload. Pure.
  I validate(StudyModeInput input);

  /// Step 2 — the mode's pure evaluation of the validated input (the §3
  /// `evaluate` step; [evaluate] itself is the sealed public entry point).
  R assess(I input);

  /// Step 3 — map the evaluation result to canonical evidence.
  CanonicalModeEvidence mapCanonicalEvidence(I input, R result);
}
