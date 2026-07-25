import 'dart:ui';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/router_providers.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';
import 'package:memox_v6/core/logging/app_logger.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';

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

  group('default pipeline', () {
    late FlutterExceptionHandler? previousOnError;
    late ErrorCallback? previousPlatformOnError;
    late ErrorWidgetBuilder previousErrorWidgetBuilder;
    late LogSink previousSink;
    late List<LogRecord> records;

    setUp(() {
      previousOnError = FlutterError.onError;
      previousPlatformOnError = PlatformDispatcher.instance.onError;
      previousErrorWidgetBuilder = ErrorWidget.builder;
      previousSink = AppLogger.sink;
      records = <LogRecord>[];
      AppLogger.sink = records.add;
    });

    tearDown(() {
      FlutterError.onError = previousOnError;
      PlatformDispatcher.instance.onError = previousPlatformOnError;
      ErrorWidget.builder = previousErrorWidgetBuilder;
      AppLogger.sink = previousSink;
    });

    test('reportToAppLogger emits a fatal record', () {
      reportToAppLogger(
        FlutterErrorDetails(
          exception: StateError('pipeline failure'),
          stack: StackTrace.current,
        ),
      );

      expect(records.single.level, LogLevel.fatal);
      expect(records.single.message, contains('pipeline failure'));
      expect(records.single.error, isA<StateError>());
    });

    test('installGlobalErrorHandlers replaces ErrorWidget.builder', () {
      installGlobalErrorHandlers(reportToAppLogger);

      final widget = ErrorWidget.builder(
        FlutterErrorDetails(exception: StateError('build failure')),
      );

      expect(widget, isA<SafeBuildErrorSurface>());
    });

    testWidgets('safe surface shows localized copy under the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SafeBuildErrorSurface(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testWidgets('safe surface degrades to an icon without localizations', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SafeBuildErrorSurface(),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
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
    await tester.pumpWidget(
      buildRoot(
        overrides: [
          appRouterInstanceProvider.overrideWithValue(createAppRouter()),
          // Home is the async Today entry (WBS 5.7.2); pin a resolved
          // projection so it settles instead of spinning forever.
          todayProjectionProvider.overrideWith(
            (ref) async => const TodayProjection(
              primaryAction: TodayPrimaryAction.caughtUp,
              dueCount: 0,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The Today title also labels the nav tab.
    expect(find.text('Today'), findsWidgets);
  });
}
