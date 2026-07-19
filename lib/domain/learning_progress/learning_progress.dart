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
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isDueAt(DateTime nowUtc) {
    final due = dueAt;
    return due != null && !due.isAfter(nowUtc);
  }
}
