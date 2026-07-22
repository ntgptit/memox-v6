import 'package:memox_v6/core/random/deterministic_random.dart';

/// The current shuffle formula version. Any change to the seed hash or the
/// shuffle arithmetic must bump this so persisted orders stay replayable and a
/// new version derives new seeds (Study Mode README, order-randomization).
const int kRoundOrderShuffleVersion = 1;

/// Version-stable seed for a mode round:
/// `MODE_ROUND_ORDER_SEED = hash(sessionId, modeId, roundIndex, shuffleVersion)`
/// (Study Mode README, order-randomization). The hash is FNV-1a/64 over a
/// delimiter-joined key; it is defined by its own arithmetic so an SDK upgrade
/// can never change an existing order. The same session/mode/round/version
/// always yields the same seed; a new session, mode or round yields a new one.
int roundOrderSeed({
  required String sessionId,
  required String modeId,
  required int roundIndex,
  int shuffleVersion = kRoundOrderShuffleVersion,
}) {
  // Unit-separator delimiter: it never appears in ids or the numeric fields, so
  // distinct tuples can never collide into the same key string.
  const separator = '';
  final key =
      '$sessionId$separator$modeId$separator$roundIndex$separator'
      '$shuffleVersion';

  const offsetBasis = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  var hash = offsetBasis;
  for (var i = 0; i < key.length; i++) {
    hash ^= key.codeUnitAt(i);
    hash *= prime; // 64-bit two's-complement wrap, like DeterministicRandom.
  }
  return hash;
}

/// Deterministic presentation-order policy for a mode round (WBS 5.5.3; Study
/// Mode README, order-randomization). Pure: it only reorders identities and
/// never changes membership, evidence or answers.
///
/// The same (session, mode, round, version, membership) always rebuilds the
/// same order, so a re-render, persistence retry or Exit/Resume that recomputes
/// it gets a byte-identical result — the Session persists the order in its
/// checkpoint and never reshuffles.
class RoundOrderPolicy {
  const RoundOrderPolicy({this.shuffleVersion = kRoundOrderShuffleVersion});

  final int shuffleVersion;

  /// The order for a round's [cardIds] (the stage cards for round 1, the
  /// deduped failed set for a retry round). When [previousSequence] is given
  /// and two or more cards would land in that exact order, the collision is
  /// resolved by a deterministic single rotation so the round never repeats the
  /// immediately-preceding sequence. A single card (or none) is returned
  /// unchanged — it is the one case order cannot vary.
  List<String> order({
    required String sessionId,
    required String modeId,
    required int roundIndex,
    required List<String> cardIds,
    List<String>? previousSequence,
  }) {
    if (cardIds.length < 2) return List<String>.of(cardIds);

    final seed = roundOrderSeed(
      sessionId: sessionId,
      modeId: modeId,
      roundIndex: roundIndex,
      shuffleVersion: shuffleVersion,
    );
    final shuffled = deterministicShuffle(cardIds, seed);

    if (previousSequence == null || !_sameOrder(shuffled, previousSequence)) {
      return shuffled;
    }
    // Rotate left by one: for two or more distinct ids this always differs from
    // the colliding sequence, and stays deterministic.
    return <String>[...shuffled.skip(1), shuffled.first];
  }

  bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
