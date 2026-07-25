import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// The single canonical evidence a Study Mode strategy returns to the Session
/// writer (WBS 5.5.1; `map-mode-outcome.md` §§2,3,7). It is mode-agnostic: the
/// Session classifies mastery and schedules from these shared fields without
/// switching on the mode's presentation detail.
///
/// It retains exactly the audit data needed to rebuild retry rounds and replay
/// deterministically — card/pair identity, `roundIndex`, the source
/// [eventId] and the [mappingVersion] — and no surplus presentation state. The
/// same committed evidence always yields the same mastery classification.
class CanonicalModeEvidence {
  const CanonicalModeEvidence({
    required this.mode,
    required this.outcome,
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
    required this.mappingVersion,
    this.pairId,
    this.reason,
  });

  /// The mode that produced this evidence.
  final StudyModeType mode;

  /// The canonical outcome (`map-mode-outcome.md` §2).
  final ModeOutcome outcome;

  /// The card under study — the mastery-round membership key.
  final String cardId;

  /// The pairing under study for pair modes (Match); `null` for others.
  final String? pairId;

  /// The zero-based mastery round the evidence belongs to.
  final int roundIndex;

  /// Stable identity of the source interaction event; the map/apply is
  /// idempotent on it (at most once, `map-mode-outcome.md` §1).
  final String eventId;

  /// The mapping (formula) version, sufficient to audit and replay; older
  /// versions stay readable and are never silently remapped (§5).
  final int mappingVersion;

  /// Optional metadata reason (v1: only `timeout`, from a Recall countdown).
  final ModeOutcomeReason? reason;
}
