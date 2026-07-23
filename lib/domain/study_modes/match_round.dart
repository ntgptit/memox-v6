import 'package:memox_v6/domain/study_modes/mode_outcome.dart';

/// The in-round board state for a Match stage (WBS 5.6.6; SM-MATCH-v1,
/// `answer-study-stage.md` §21, §70-72).
///
/// A pure, immutable state machine over term **pair ids**. Only a `correct`
/// pairing locks a tile (SM-MATCH-001); a `wrong` (SM-MATCH-002) or `almost`
/// (SM-MATCH-003) pairing adds the term-owner card to a **sticky** failed set —
/// a later correct pairing completes the tile (so the round can finish) but does
/// not clear the lapse (SM-MATCH-004, §72). The round is complete once every
/// pair is locked; [outcomeFor] then drives the mastery-round failed set and the
/// terminal SRS grade, so the board itself persists nothing.
///
/// The board holds only ephemeral UI state (tiles, selection, this round); a
/// mid-board app kill restarts the board on resume — durable mid-board resume is
/// WBS 5.6.12, not this stage.
class MatchRound {
  const MatchRound._(this._pairIds, this._locked, this._lapsed);

  /// Opens a round over [pairIds] (the term-owner card ids of the current
  /// round, each its own pair), nothing locked or lapsed yet.
  factory MatchRound.of(Iterable<String> pairIds) => MatchRound._(
    List<String>.unmodifiable(pairIds),
    const <String>{},
    const <String, ModeOutcome>{},
  );

  final List<String> _pairIds;
  final Set<String> _locked;
  final Map<String, ModeOutcome> _lapsed;

  /// Applies one resolved pairing. [outcome] is the SM-MATCH-v1 classification
  /// of the term against the selected meaning tile: [ModeOutcome.correct] locks
  /// the pair; [ModeOutcome.wrong] or [ModeOutcome.almost] records a lapse (the
  /// first one sticks) and leaves the tile unlocked so the learner retries.
  ///
  /// [ModeOutcome.reviewed] is not a Match classification and is ignored.
  MatchRound resolve({
    required String termPairId,
    required ModeOutcome outcome,
  }) {
    if (outcome == ModeOutcome.reviewed) return this;
    if (outcome == ModeOutcome.correct) {
      if (_locked.contains(termPairId)) return this;
      return MatchRound._(_pairIds, <String>{..._locked, termPairId}, _lapsed);
    }
    // wrong / almost: a sticky lapse; keep the first outcome and leave the tile
    // unlocked (the learner must still find the correct meaning to complete it).
    if (_lapsed.containsKey(termPairId)) return this;
    return MatchRound._(_pairIds, _locked, <String, ModeOutcome>{
      ..._lapsed,
      termPairId: outcome,
    });
  }

  /// The pairs in cursor order (the round's card ids).
  List<String> get pairIds => _pairIds;

  int get pairCount => _pairIds.length;

  /// Pairs completed by a correct match — the board's progress numerator.
  int get lockedCount => _locked.length;

  bool isLocked(String pairId) => _locked.contains(pairId);

  bool hasLapsed(String pairId) => _lapsed.containsKey(pairId);

  /// Every pair is locked, so the board is finished and can be flushed.
  bool get isComplete => _locked.length == _pairIds.length;

  /// The card's committed round outcome: its first lapse if any, else `correct`
  /// (§21 "pair đúng ngay trong round"; §72 a pass never clears a prior lapse).
  ModeOutcome outcomeFor(String pairId) =>
      _lapsed[pairId] ?? ModeOutcome.correct;

  /// Whether the card passed the round (no lapse) — drives the failed set.
  bool passedFor(String pairId) => !_lapsed.containsKey(pairId);
}
