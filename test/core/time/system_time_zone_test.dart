import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';

/// `SystemTimeZone.id` must never be the reason the app fails to start.
///
/// `DateTime.timeZoneName` is not safe to read unguarded on Web: the
/// implementation asks the browser's `Intl` for the zone, and a host whose
/// locale it cannot use throws `RangeError: Incorrect locale information
/// provided`. A CI runner with no `LANG` set is such a host, and the shipping
/// app died on a white screen there before painting a frame (`int-88`).
void main() {
  test('the zone id is readable on this host', () {
    expect(const SystemTimeZone().id, isNotEmpty);
  });

  // The guard cannot be driven from a Dart VM test — `timeZoneName` does not
  // throw here — so this pins the fallback it returns instead, which is the
  // half a future edit could silently drop.
  test('a host that will not name its zone is recorded as unknown', () {
    expect(SystemTimeZone.unknownZoneId, 'unknown');
    expect(
      const FixedOffsetTimeZone(
        id: SystemTimeZone.unknownZoneId,
        offset: Duration.zero,
      ).id,
      'unknown',
      reason: 'the same value a day record would carry',
    );
  });

  // The day boundary must not depend on the zone name at all — that is what
  // makes the fallback safe rather than merely quiet.
  test('local day and time need no zone name', () {
    const zone = SystemTimeZone();
    final instant = DateTime.utc(2026, 7, 27, 12);
    expect(zone.localTimeOf(instant), instant.toLocal());
    expect(zone.localDayOf(instant).toString(), isNotEmpty);
  });
}
