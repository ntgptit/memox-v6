import 'package:memox_v6/core/time/app_clock.dart';

/// Mutable test clock; WBS 1.10 expands the shared harness around it.
final class FakeClock implements AppClock {
  FakeClock(DateTime initial) : _now = initial.toUtc();

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void advance(Duration duration) => _now = _now.add(duration);

  set now(DateTime value) => _now = value.toUtc();
}
