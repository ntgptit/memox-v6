import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
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

@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();
