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

  @override
  String get id => DateTime.now().timeZoneName;

  @override
  LocalDay localDayOf(DateTime utcInstant) => LocalDay.of(utcInstant.toLocal());
}

/// A fixed-offset zone, for tests and for the day-boundary cases that only
/// appear away from UTC.
final class FixedOffsetTimeZone implements AppTimeZone {
  const FixedOffsetTimeZone({required this.id, required this.offset});

  @override
  final String id;

  final Duration offset;

  @override
  LocalDay localDayOf(DateTime utcInstant) =>
      LocalDay.of(utcInstant.toUtc().add(offset));
}
