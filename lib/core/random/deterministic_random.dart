/// Version-stable seeded PRNG (xorshift64*).
///
/// `dart:math` `Random(seed)` does not guarantee an identical sequence
/// across SDK releases, but persisted session shuffle orders must replay
/// byte-identically forever (WBS 5.5.3). This implementation is defined by
/// its own arithmetic, so upgrades can never change existing orders.
final class DeterministicRandom {
  DeterministicRandom(int seed)
    // Seed 0 is a fixed point of xorshift; displace it deterministically.
    : _state = seed == 0 ? _zeroSeedReplacement : seed;

  static const int _zeroSeedReplacement = 0x9E3779B97F4A7C15;
  static const int _multiplier = 0x2545F4914F6CDD1D;

  int _state;

  /// Next value in `[0, maxExclusive)`.
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'must be > 0');
    }
    var x = _state;
    x ^= (x >>> 12);
    x ^= (x << 25);
    x ^= (x >>> 27);
    _state = x;
    final value = (x * _multiplier) >>> 1;
    return value % maxExclusive;
  }
}

/// Pure Fisher–Yates shuffle: returns a new list, never mutates [items],
/// and produces the identical order for an identical [seed].
List<T> deterministicShuffle<T>(List<T> items, int seed) {
  final result = List<T>.of(items);
  final random = DeterministicRandom(seed);
  for (var i = result.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final swap = result[i];
    result[i] = result[j];
    result[j] = swap;
  }
  return result;
}
