import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The single contract every Study Mode strategy exposes (WBS 5.5.2;
/// factory-di-architecture §§2,3). The factory resolves a [StudyModeType] to
/// one of these, and callers use it uniformly — they never switch on the mode
/// again.
///
/// A strategy is pure domain: given typed input and an immutable prompt
/// snapshot it validates and returns [CanonicalModeEvidence]. It persists no
/// attempt, advances no checkpoint, builds no retry round, schedules no SRS and
/// imports no Flutter/Riverpod/Drift/clock — those belong to Study Session and
/// Learning Progress.
abstract interface class StudyModeStrategy {
  /// The mode this strategy implements; the factory guarantees it matches the
  /// resolved [StudyModeType].
  StudyModeType get mode;

  /// Validate the interaction and return its canonical evidence, or throw a
  /// typed failure for an unsupported/mismatched input. Deterministic and
  /// side-effect free.
  CanonicalModeEvidence evaluate(StudyModeInput input);
}
