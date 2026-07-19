/// Immutable card snapshot taken at session start (WBS 4.5): what the
/// learner actually sees, pinned by content and progress versions.
class SessionCardSnapshot {
  const SessionCardSnapshot({
    required this.id,
    required this.sessionId,
    required this.cardId,
    required this.displayOrder,
    required this.term,
    required this.meaning,
    required this.contentVersion,
    required this.progressBox,
    required this.progressRevision,
  });

  final String id;
  final String sessionId;
  final String cardId;
  final int displayOrder;
  final String term;
  final String meaning;
  final int contentVersion;
  final int progressBox;
  final int progressRevision;
}
