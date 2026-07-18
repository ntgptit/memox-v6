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
