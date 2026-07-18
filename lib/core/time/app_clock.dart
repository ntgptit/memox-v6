import 'package:clock/clock.dart';

/// Injected time source; every time read in domain/data flows through this
/// port so SRS scheduling, sessions and projections stay deterministic in
/// tests (ADR-003).
abstract interface class AppClock {
  /// Current instant, always in UTC.
  DateTime nowUtc();
}

/// Production clock backed by `package:clock`, so `withClock` zones in tests
/// compose with code that received this port.
final class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime nowUtc() => clock.now().toUtc();
}
