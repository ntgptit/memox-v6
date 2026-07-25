import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_providers.g.dart';

/// Core infrastructure providers (WBS 1.11).
///
/// Every time read and generated id flows through these ports; tests
/// override them with the deterministic fakes from `test/support/`.
/// Infrastructure providers are keep-alive by contract
/// (`docs/architecture/riverpod-foundation.md`) — the 4.8 DI graph adds
/// database and repository providers beside them.

@Riverpod(keepAlive: true)
AppClock appClock(Ref ref) => const SystemClock();

/// The zone that turns an instant into the local day a record belongs to.
/// Separate from the clock so day-boundary behaviour can be pinned in tests
/// without moving the clock (`handle-streak-boundary.md`).
@Riverpod(keepAlive: true)
AppTimeZone appTimeZone(Ref ref) => const SystemTimeZone();

@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();
