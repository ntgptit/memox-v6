/// Append-only study attempt evidence (WBS 4.5).
class StudyAttempt {
  const StudyAttempt({
    required this.id,
    required this.idempotencyKey,
    required this.cardId,
    required this.sessionId,
    required this.modeId,
    required this.outcome,
    required this.evidenceJson,
    required this.isTerminal,
    required this.createdAt,
  });

  final String id;
  final String idempotencyKey;
  final String cardId;
  final String? sessionId;
  final String modeId;
  final String outcome;
  final String evidenceJson;
  final bool isTerminal;
  final DateTime createdAt;
}
