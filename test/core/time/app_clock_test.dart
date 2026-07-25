import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';

import '../../support/fake_clock.dart';

void main() {
  test('SystemClock returns UTC instants', () {
    final now = const SystemClock().nowUtc();

    expect(now.isUtc, isTrue);
  });

  test('SystemClock composes with package:clock test zones', () {
    final fixed = DateTime.utc(2026, 7, 19, 12);

    withClock(Clock.fixed(fixed), () {
      expect(const SystemClock().nowUtc(), fixed);
    });
  });

  // WBS 5.4.5. The zone pinned above is already UTC, so it passes whether or
  // not `nowUtc()` converts. The first test does catch a dropped `.toUtc()`
  // (`DateTime.now()` is never flagged UTC), but only via the flag — it says
  // nothing about the value. This one runs inside a non-UTC `withClock` zone
  // and asserts the *instant* survives conversion, which is what everything
  // downstream actually relies on: SRS due comparison, session timestamps and
  // the local-day projections all read this port without re-checking it.
  test('SystemClock converts a non-UTC ambient clock', () {
    final local = DateTime(2026, 7, 19, 12);

    withClock(Clock.fixed(local), () {
      final now = const SystemClock().nowUtc();

      expect(now.isUtc, isTrue);
      expect(now.isAtSameMomentAs(local), isTrue);
    });
  });

  test('FakeClock advances deterministically', () {
    final fakeClock = FakeClock(DateTime.utc(2026, 1, 1));

    fakeClock.advance(const Duration(days: 3));

    expect(fakeClock.nowUtc(), DateTime.utc(2026, 1, 4));
    expect(fakeClock.nowUtc().isUtc, isTrue);
  });

  test('FakeClock normalizes assigned instants to UTC', () {
    final fakeClock = FakeClock(DateTime.utc(2026, 1, 1))
      ..now = DateTime(2026, 6, 1, 8);

    expect(fakeClock.nowUtc().isUtc, isTrue);
  });
}
