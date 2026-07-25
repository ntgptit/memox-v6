/// Learning Progress domain model (WBS 4.5): one per card. Box and due
/// date always arrive from the SRS policy; this model only carries the
/// persisted result.
class LearningProgress {
  const LearningProgress({
    required this.id,
    required this.cardId,
    required this.box,
    required this.dueAt,
    required this.policyId,
    required this.policyVersion,
    required this.revision,
    required this.repetitionCount,
    required this.lapseCount,
    required this.lastTerminalAttemptId,
    required this.srsActivatedAt,
    required this.lastReviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String cardId;
  final int box;
  final DateTime? dueAt;
  final String policyId;
  final int policyVersion;
  final int revision;
  final int repetitionCount;
  final int lapseCount;
  final String? lastTerminalAttemptId;

  /// When the card first entered Box 1 (SRS policy §3); never moves again.
  ///
  /// NULL carries two meanings, separated by [box]: at Box 0 the card has
  /// never been activated, while `box >= 1` with a NULL activation is a row
  /// written before schema v2, when no column held the instant. The v2
  /// migration deliberately left those NULL rather than invent a value.
  final DateTime? srsActivatedAt;

  /// The instant the most recent terminal grade was applied (SRS policy §8),
  /// or NULL for a card that has never been graded.
  final DateTime? lastReviewedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool isDueAt(DateTime nowUtc) {
    final due = dueAt;
    return due != null && !due.isAfter(nowUtc);
  }
}
