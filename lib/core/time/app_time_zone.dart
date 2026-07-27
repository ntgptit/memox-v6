import 'package:memox_v6/domain/study_streak/streak_projection_policy.dart';

/// Resolves the local calendar day an instant belongs to (ADR-003 companion to
/// [AppClock]).
///
/// A second port rather than more methods on the clock, because they answer
/// different questions and fail differently: the clock says *when*, this says
/// *which day that was for this user*. `metrics-v1` defines `localDayId` as
/// "date derived once from event UTC instant using the effective IANA timezone
/// snapshot", and `handle-streak-boundary.md` forbids deriving days from
/// elapsed 24-hour spans — both need a seam that tests can pin.
abstract interface class AppTimeZone {
  /// The zone identifier stored alongside a day record, so a later
  /// reconciliation can tell which zone produced it.
  String get id;

  /// The local calendar day [utcInstant] falls in.
  LocalDay localDayOf(DateTime utcInstant);

  /// The local wall-clock reading of [utcInstant].
  ///
  /// The same question [localDayOf] answers, at finer grain — anything that
  /// needs the hour rather than the date (the dashboard greeting) must ask
  /// this rather than `DateTime.toLocal()`, which reads the host's zone and
  /// so can disagree with the zone every day record was written in.
  DateTime localTimeOf(DateTime utcInstant);
}

/// The platform's local zone.
///
/// `id` reports `DateTime.timeZoneName`, which is an abbreviation ("GMT+7",
/// "ICT") rather than an IANA identifier — Dart core exposes no IANA name, and
/// obtaining one needs a platform channel. The `timezone` package is already a
/// dependency for when that lands; until then this records what the platform
/// actually reported rather than a plausible-looking invention, and the port
/// means swapping it touches no domain code.
final class SystemTimeZone implements AppTimeZone {
  const SystemTimeZone();

  /// What the host calls its zone, or [unknownZoneId] when it will not say.
  ///
  /// `DateTime.timeZoneName` is not safe to read unguarded on Web: the
  /// implementation asks the browser's `Intl` for the zone, and a host whose
  /// locale it cannot use throws `RangeError: Incorrect locale information
  /// provided` instead of returning anything. A CI runner with no `LANG` set
  /// is exactly such a host, and the shipping app died on a white screen there
  /// before the first frame — found by the Tier-1 Web smoke (`int-88`).
  ///
  /// The identifier is bookkeeping: it travels with a day record so a later
  /// reconciliation can tell which zone produced it. Not knowing it is a
  /// smaller problem than not starting, and recording that it was unknown is
  /// honest where inventing `UTC` would not be — the day boundaries still come
  /// from [localTimeOf], which needs no locale at all.
  @override
  String get id {
    try {
      return DateTime.now().timeZoneName;
    } on Object {
      return unknownZoneId;
    }
  }

  /// Recorded when the host will not report a zone name.
  static const String unknownZoneId = 'unknown';

  @override
  DateTime localTimeOf(DateTime utcInstant) => utcInstant.toLocal();

  // Derived from the time so the two readings cannot diverge.
  @override
  LocalDay localDayOf(DateTime utcInstant) =>
      LocalDay.of(localTimeOf(utcInstant));
}

/// A fixed-offset zone, for tests and for the day-boundary cases that only
/// appear away from UTC.
final class FixedOffsetTimeZone implements AppTimeZone {
  const FixedOffsetTimeZone({required this.id, required this.offset});

  @override
  final String id;

  final Duration offset;

  @override
  DateTime localTimeOf(DateTime utcInstant) => utcInstant.toUtc().add(offset);

  @override
  LocalDay localDayOf(DateTime utcInstant) =>
      LocalDay.of(localTimeOf(utcInstant));
}
