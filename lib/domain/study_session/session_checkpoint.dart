/// Resumable session position (WBS 4.5): stage/round/card plus the
/// failed set; the timer state stays an opaque versioned payload owned
/// by the study runtime.
class SessionCheckpoint {
  const SessionCheckpoint({
    required this.id,
    required this.sessionId,
    required this.stageIndex,
    required this.roundIndex,
    required this.cardPosition,
    required this.failedCardIds,
    required this.timerStateJson,
    required this.stateVersion,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final int stageIndex;
  final int roundIndex;
  final int cardPosition;
  final List<String> failedCardIds;
  final String timerStateJson;
  final int stateVersion;
  final DateTime updatedAt;
}
