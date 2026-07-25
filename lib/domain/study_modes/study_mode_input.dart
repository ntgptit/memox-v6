import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The typed input boundary every Study Mode strategy validates (WBS 5.5.1;
/// factory-di-architecture §3, `validate(input) → evaluate → mapCanonicalEvidence`).
///
/// It carries only the identity shared by all modes; each concrete strategy
/// (5.5.4) implements this with its own mode-specific interaction payload. The
/// contract is pure domain — no Flutter/Riverpod/Drift and no UI event types
/// (a tap, a gesture, localized copy) may leak across it.
///
/// [eventId] is the source interaction's stable identity: the mapping to
/// canonical evidence is idempotent on it, applied at most once
/// (`map-mode-outcome.md` §1). The Session, not the strategy, later creates the
/// persisted attempt identity.
abstract interface class StudyModeInput {
  /// The mode this input is destined for; a strategy rejects a mismatch.
  StudyModeType get mode;

  /// The active session the interaction belongs to.
  String get sessionId;

  /// The card under study — the mastery-round membership key.
  String get cardId;

  /// The zero-based mastery round the interaction occurred in.
  int get roundIndex;

  /// Stable identity of the source interaction event (idempotent mapping key).
  String get eventId;
}
