import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/round_order_policy.dart';

/// WBS 5.5.3 — deterministic shuffle/round policy: version-stable seed,
/// collision resolution, persisted-order stability across resume (Study Mode
/// README, order-randomization).
void main() {
  const policy = RoundOrderPolicy();
  final cards = <String>['a', 'b', 'c', 'd', 'e'];

  List<String> order(
    String modeId,
    int round, {
    List<String>? previous,
    List<String>? items,
  }) => policy.order(
    sessionId: 'sess-1',
    modeId: modeId,
    roundIndex: round,
    cardIds: items ?? cards,
    previousSequence: previous,
  );

  group('seed', () {
    test('same tuple → same seed; any differing field → different seed', () {
      int seed(String s, String m, int r, int v) => roundOrderSeed(
        sessionId: s,
        modeId: m,
        roundIndex: r,
        shuffleVersion: v,
      );

      expect(seed('s1', 'guess', 0, 1), seed('s1', 'guess', 0, 1));
      expect(seed('s1', 'guess', 0, 1), isNot(seed('s2', 'guess', 0, 1)));
      expect(seed('s1', 'guess', 0, 1), isNot(seed('s1', 'match', 0, 1)));
      expect(seed('s1', 'guess', 0, 1), isNot(seed('s1', 'guess', 1, 1)));
      expect(seed('s1', 'guess', 0, 1), isNot(seed('s1', 'guess', 0, 2)));
    });
  });

  group('order', () {
    test('is a stable permutation — identical inputs replay identically', () {
      final first = order('guess', 0);
      final again = order('guess', 0);
      expect(again, first, reason: 'resume must recompute the same order');
      expect(
        first.toSet(),
        cards.toSet(),
        reason: 'no card lost or duplicated',
      );
      expect(first.length, cards.length);
    });

    test('a single card (or none) is never reordered', () {
      expect(order('guess', 0, items: <String>['solo']), <String>['solo']);
      expect(order('guess', 0, items: <String>[]), isEmpty);
    });

    test('a different mode round produces its own order', () {
      // Different seeds → orders should differ for a 5-card set.
      expect(order('guess', 0), isNot(order('match', 0)));
      expect(order('guess', 0), isNot(order('guess', 1)));
    });

    test('collision with the previous sequence is resolved to a new order', () {
      // The natural order with no previous constraint...
      final natural = order('guess', 0);
      // ...then forced as the previous sequence must not be repeated.
      final resolved = order('guess', 0, previous: natural);
      expect(resolved, isNot(natural));
      expect(resolved.toSet(), natural.toSet(), reason: 'same membership');
    });

    test('no collision when the natural order already differs', () {
      final natural = order('guess', 0);
      final unrelated = <String>['e', 'd', 'c', 'b', 'a'];
      // Only resolve when it actually collides; here it does not.
      if (!_eq(natural, unrelated)) {
        expect(order('guess', 0, previous: unrelated), natural);
      }
    });
  });
}

bool _eq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
