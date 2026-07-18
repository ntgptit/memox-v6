import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/random/deterministic_random.dart';

void main() {
  test('known-answer sequence is locked across releases', () {
    // If this test ever fails after an SDK/package upgrade, persisted
    // shuffle orders would replay differently — that is a contract break,
    // not a test to update casually (WBS 5.5.3 / ADR-003).
    final random = DeterministicRandom(42);
    expect(List<int>.generate(6, (_) => random.nextInt(1000)), <int>[
      800,
      749,
      923,
      367,
      339,
      937,
    ]);

    final zeroSeeded = DeterministicRandom(0);
    expect(List<int>.generate(3, (_) => zeroSeeded.nextInt(100)), <int>[
      5,
      43,
      56,
    ]);
  });

  test('identical seeds produce identical sequences', () {
    final first = DeterministicRandom(1234);
    final second = DeterministicRandom(1234);

    for (var i = 0; i < 100; i++) {
      expect(first.nextInt(1 << 20), second.nextInt(1 << 20));
    }
  });

  test('nextInt validates its bound', () {
    expect(() => DeterministicRandom(1).nextInt(0), throwsArgumentError);
    expect(() => DeterministicRandom(1).nextInt(-5), throwsArgumentError);
  });

  group('deterministicShuffle', () {
    test('is stable for an identical seed (known answer)', () {
      final items = List<int>.generate(8, (i) => i);

      expect(deterministicShuffle(items, 7), <int>[5, 6, 2, 0, 4, 3, 1, 7]);
      expect(deterministicShuffle(items, 7), <int>[5, 6, 2, 0, 4, 3, 1, 7]);
    });

    test('does not mutate its input', () {
      final items = <int>[1, 2, 3, 4, 5];

      deterministicShuffle(items, 99);

      expect(items, <int>[1, 2, 3, 4, 5]);
    });

    test('different seeds reorder the fixture differently', () {
      final items = List<int>.generate(8, (i) => i);

      expect(
        deterministicShuffle(items, 7),
        isNot(equals(deterministicShuffle(items, 8))),
      );
    });

    test('handles empty and single-element lists', () {
      expect(deterministicShuffle(<int>[], 1), isEmpty);
      expect(deterministicShuffle(<int>[42], 1), <int>[42]);
    });
  });
}
