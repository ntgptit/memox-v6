/// How much of a language pair's library is mastered (kit `dashboard/today`
/// "library mastered" stat).
///
/// Mastered is Box 8 — `srs-8-box-policy.md` §3: no further scheduling, no due
/// date, outside every study queue. The same rule the deck-row bar reads, so
/// the strip and the rows below it cannot disagree.
class LibraryMastery {
  const LibraryMastery({
    required this.masteredCount,
    required this.studiableCount,
  });

  const LibraryMastery.empty() : masteredCount = 0, studiableCount = 0;

  final int masteredCount;

  /// Cards that can be studied at all: not deleted, not hidden. A hidden card
  /// can never reach Box 8, so counting it would put 100% out of reach.
  final int studiableCount;

  /// `0.0`–`1.0`. An empty library is zero rather than undefined: the stat
  /// reads "0%", which is true of a library with nothing in it.
  double get fraction =>
      studiableCount == 0 ? 0 : masteredCount / studiableCount;
}
