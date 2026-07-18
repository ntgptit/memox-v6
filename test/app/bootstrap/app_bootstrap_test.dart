import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installGlobalErrorHandlers', () {
    late FlutterExceptionHandler? previousOnError;
    late ErrorCallback? previousPlatformOnError;

    setUp(() {
      previousOnError = FlutterError.onError;
      previousPlatformOnError = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = previousOnError;
      PlatformDispatcher.instance.onError = previousPlatformOnError;
    });

    test('routes framework errors to the reporter', () {
      final reported = <FlutterErrorDetails>[];
      installGlobalErrorHandlers(reported.add);

      final details = FlutterErrorDetails(
        exception: StateError('framework failure'),
        stack: StackTrace.current,
      );
      FlutterError.reportError(details);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isA<StateError>());
    });

    test('routes platform-dispatcher errors and marks them handled', () {
      final reported = <FlutterErrorDetails>[];
      installGlobalErrorHandlers(reported.add);

      final handled = PlatformDispatcher.instance.onError!(
        StateError('platform failure'),
        StackTrace.current,
      );

      expect(handled, isTrue);
      expect(reported, hasLength(1));
      expect(reported.single.exception, isA<StateError>());
      expect(reported.single.stack, isNotNull);
    });
  });

  test('detailsForUncaughtError preserves error and stack', () {
    final error = StateError('zone failure');
    final stackTrace = StackTrace.current;

    final details = detailsForUncaughtError(error, stackTrace);

    expect(details.exception, same(error));
    expect(details.stack, same(stackTrace));
    expect(details.library, 'memox bootstrap');
  });

  testWidgets('lifecycle listener delivers state transitions', (tester) async {
    final states = <AppLifecycleState>[];
    final listener = installLifecycleListener(states.add);
    addTearDown(listener.dispose);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    expect(
      states,
      containsAllInOrder(<AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]),
    );
  });

  testWidgets('buildRoot applies provider overrides', (tester) async {
    await tester.pumpWidget(buildRoot());
    await tester.pumpAndSettle();

    expect(find.text('MemoX Home'), findsOneWidget);
  });
}
