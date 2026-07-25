/// Version-stable seeded PRNG (xorshift64*).
///
/// `dart:math` `Random(seed)` does not guarantee an identical sequence across
/// SDK releases, but persisted session shuffle orders must replay
/// byte-identically forever (WBS 5.5.3). This implementation is defined by its
/// own 64-bit arithmetic, carried in [BigInt] masked to 64 bits so it produces
/// the **identical** sequence on native (where `int` is 64-bit) and on the web
/// (dart2js, where `int` is only 53-bit exact and a 64-bit literal cannot even
/// compile). BigInt is exact on both, and a shuffle touches only a handful of
/// items, so the cost is negligible.
final class DeterministicRandom {
  DeterministicRandom(int seed)
    : _state = seed == 0
          ? _zeroSeedReplacement
          : BigInt.from(seed).toUnsigned(64);

  static final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;
  // Seed 0 is a fixed point of xorshift; displace it deterministically.
  static final BigInt _zeroSeedReplacement = BigInt.parse(
    '9E3779B97F4A7C15',
    radix: 16,
  );
  static final BigInt _multiplier = BigInt.parse('2545F4914F6CDD1D', radix: 16);

  BigInt _state;

  /// Next value in `[0, maxExclusive)`.
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'must be > 0');
    }
    var x = _state;
    x ^= x >> 12;
    x = (x ^ ((x << 25) & _mask64)) & _mask64;
    x ^= x >> 27;
    _state = x;
    final value = ((x * _multiplier) & _mask64) >> 1;
    return (value % BigInt.from(maxExclusive)).toInt();
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
