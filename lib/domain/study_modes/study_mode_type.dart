/// The closed set of Study Mode strategies (WBS 5.5.1; Study Mode
/// factory-di-architecture §1). Exactly six values — a factory resolves each to
/// one pure strategy (5.5.5), so adding a value here forces the exhaustive
/// factory and its tests to fail until a strategy exists.
///
/// `srsBinaryReview` is session-only: it is chosen by a versioned Due
/// Review / Relearn plan and never appears in the Practice picker.
enum StudyModeType {
  review('review'),
  match('match'),
  guess('guess'),
  recall('recall'),
  fill('fill'),
  srsBinaryReview('srsBinaryReview');

  const StudyModeType(this.id);

  /// Stable persisted identity (`StudyAttempt.modeId`); never localized and
  /// never reused, so history stays replayable across releases.
  final String id;

  /// Fail-closed parse of a persisted id: returns `null` for an unknown value
  /// so the caller maps it to a typed failure rather than guessing a mode.
  static StudyModeType? tryFromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}
