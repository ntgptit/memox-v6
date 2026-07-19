import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';
import '../../support/test_container.dart';

part 'riverpod_foundation_test.g.dart';

final _disposedKeys = <int>[];

/// Test-local generated family provider exercising the lifecycle
/// contract; the fetcher is injectable so tests control completion.
@riverpod
Future<String> contractQuery(Ref ref, {required int key}) async {
  ref.onDispose(() => _disposedKeys.add(key));
  final fetch = ref.watch(contractFetcherProvider);
  return fetch(key);
}

@Riverpod(keepAlive: true)
Future<String> Function(int key) contractFetcher(Ref ref) {
  return (key) async => 'value-$key';
}

void main() {
  test('infrastructure providers are keep-alive and overridable', () async {
    final clock = FakeClock(DateTime.utc(2026, 7, 19));
    final container = createTestContainer(
      overrides: [
        appClockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );

    expect(container.read(appClockProvider).nowUtc(), clock.nowUtc());
    expect(container.read(idGeneratorProvider).newId(), 'id-1');

    // Keep-alive: with no listeners at all, the instance survives.
    final first = container.read(appClockProvider);
    await Future<void>.delayed(Duration.zero);
    expect(identical(container.read(appClockProvider), first), isTrue);
  });

  test(
    'family instances resolve per key and autoDispose when unused',
    () async {
      _disposedKeys.clear();
      final container = createTestContainer();

      final subscription = container.listen(
        contractQueryProvider(key: 1),
        (_, _) {},
      );
      final one = await container.read(contractQueryProvider(key: 1).future);
      final two = await container.read(contractQueryProvider(key: 2).future);
      expect(one, 'value-1');
      expect(two, 'value-2');

      // Dropping the last listener reclaims the autoDispose instance.
      subscription.close();
      await Future<void>.delayed(Duration.zero);
      expect(_disposedKeys, contains(1));
    },
  );

  test('mid-flight invalidation discards the stale result', () async {
    final gate = Completer<String>();
    var calls = 0;
    final container = createTestContainer(
      overrides: [
        contractFetcherProvider.overrideWithValue((key) {
          calls += 1;
          return calls == 1 ? gate.future : Future.value('fresh-$key');
        }),
      ],
    );

    final subscription = container.listen(
      contractQueryProvider(key: 7),
      (_, _) {},
    );

    container.invalidate(contractQueryProvider(key: 7));
    final fresh = await container.read(contractQueryProvider(key: 7).future);
    gate.complete('stale-7');
    await Future<void>.delayed(Duration.zero);

    expect(fresh, 'fresh-7');
    expect(
      subscription.read().value,
      'fresh-7',
      reason: 'the stale first fetch must never surface',
    );
  });

  test('invalidate is the retry path after a failure', () async {
    var attempts = 0;
    final container = createTestContainer(
      overrides: [
        contractFetcherProvider.overrideWithValue((key) async {
          attempts += 1;
          if (attempts == 1) throw StateError('transient');
          return 'recovered-$key';
        }),
      ],
    );

    final subscription = container.listen(
      contractQueryProvider(key: 3),
      (_, _) {},
    );

    await expectLater(
      container.read(contractQueryProvider(key: 3).future),
      throwsStateError,
    );

    container.invalidate(contractQueryProvider(key: 3));
    final retried = await container.read(contractQueryProvider(key: 3).future);

    expect(retried, 'recovered-3');
    expect(subscription.read().hasError, isFalse);
  });
}
