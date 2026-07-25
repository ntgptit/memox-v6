/// The canonical, persistence-facing outcome vocabulary every Study Mode maps
/// to (WBS 5.5.1; `map-mode-outcome.md` §§2,3). These are the only values that
/// may reach `StudyAttempt.outcome`; presentation-only actions
/// (`remembered`/`forgot`/`relearn`) never appear here — they live in the
/// presentation layer before mapping.
///
/// `reviewed` is Review's only, ungraded outcome; `almost` is produced only by
/// Match. Whether an outcome counts as passing in a mastery round is decided by
/// the strategy/Session with round context, not by this enum alone.
enum ModeOutcome {
  reviewed('reviewed'),
  correct('correct'),
  wrong('wrong'),
  almost('almost');

  const ModeOutcome(this.id);

  /// Stable persisted identity (`StudyAttempt.outcome`); older values stay
  /// readable, so history is never silently remapped.
  final String id;

  /// Fail-closed parse: `null` for an unknown value so the caller raises a
  /// typed failure instead of inventing an outcome.
  static ModeOutcome? tryFromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// The canonical metadata reasons a graded outcome may carry (WBS 5.5.1). v1
/// has exactly two: a Recall countdown that expires before reveal maps to
/// `wrong` with `reason = timeout` (`recall-and-self-grade.md`); a Match
/// selection of two differently-keyed tiles whose meanings normalize equal maps
/// to `almost` with `reason = duplicateNormalizedMeaning` (SM-MATCH-003).
enum ModeOutcomeReason {
  timeout('timeout'),
  duplicateNormalizedMeaning('duplicateNormalizedMeaning');

  const ModeOutcomeReason(this.id);

  /// Stable persisted identity carried in evidence metadata.
  final String id;

  /// Fail-closed parse: `null` for an unknown value.
  static ModeOutcomeReason? tryFromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}
