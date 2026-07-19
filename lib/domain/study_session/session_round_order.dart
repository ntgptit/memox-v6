/// Deterministic per-round presentation order (WBS 4.5): the seed
/// reproduces the shuffle, the persisted order is what resume replays.
class SessionRoundOrder {
  const SessionRoundOrder({
    required this.id,
    required this.sessionId,
    required this.roundIndex,
    required this.seed,
    required this.cardIds,
  });

  final String id;
  final String sessionId;
  final int roundIndex;
  final int seed;
  final List<String> cardIds;
}
