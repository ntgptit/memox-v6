import 'dart:convert';

/// The Recall countdown, carried across an exit (`exit-study-session.md` §5:
/// "Recall countdown trước reveal | Pause và persist `remainingMs`; Resume
/// tiếp tục, không reset").
///
/// This is the payload behind `study_checkpoints.timer_state_json`, which the
/// schema deliberately leaves opaque and versioned for the study runtime to
/// own. It is card-scoped: a checkpoint that has advanced to another card
/// carries a countdown that no longer applies, so the card id travels with the
/// remaining time and a mismatch reads as "no saved timer" rather than as
/// somebody else's clock.
class SessionTimerState {
  const SessionTimerState({required this.cardId, required this.remainingMs});

  /// Payload shape version. A stored payload from a future version is not
  /// guessed at — it reads as absent, and the card restarts its countdown.
  static const int version = 1;

  static const String _versionKey = 'v';
  static const String _cardIdKey = 'cardId';
  static const String _remainingKey = 'remainingMs';

  final String cardId;
  final int remainingMs;

  String encode() => jsonEncode(<String, Object?>{
    _versionKey: version,
    _cardIdKey: cardId,
    _remainingKey: remainingMs,
  });

  /// The stored countdown, or null when there is none to restore — an empty
  /// payload (what every answer writes), an unreadable one, or one from a
  /// version this build does not know.
  static SessionTimerState? decode(String json) {
    if (json.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    if (decoded[_versionKey] != version) return null;
    final cardId = decoded[_cardIdKey];
    final remainingMs = decoded[_remainingKey];
    if (cardId is! String || remainingMs is! int) return null;
    if (remainingMs <= 0) return null;
    return SessionTimerState(cardId: cardId, remainingMs: remainingMs);
  }
}
