/// Failed card queued for in-session relearn (WBS 4.5). `retryCount`
/// is the learning retry namespace, distinct from persistence retry.
class SessionRelearnItem {
  const SessionRelearnItem({
    required this.id,
    required this.sessionId,
    required this.cardId,
    required this.retryCount,
  });

  final String id;
  final String sessionId;
  final String cardId;
  final int retryCount;
}
