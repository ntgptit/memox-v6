import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_draft.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

void main() {
  group('MxAsyncDraft', () {
    test('currentValue reads data and nulls otherwise', () {
      expect(const AsyncData<int>(7).currentValue, 7);
      expect(const AsyncLoading<int>().currentValue, isNull);
      expect(
        AsyncError<int>(StateError('x'), StackTrace.current).currentValue,
        isNull,
      );
    });
  });

  group('runMxAction', () {
    test('success maps to AsyncData', () async {
      final result = await runMxAction(() async {});
      expect(result, const AsyncData<void>(null));
    });

    test('thrown errors map to AsyncError carrying AppFailure', () async {
      final result = await runMxAction(() async {
        throw StateError('save failed');
      });

      expect(result, isA<AsyncError<void>>());
      final failure = MxActionErrors.failureOf(result);
      expect(failure, isA<UnexpectedFailure>());
      expect((failure as UnexpectedFailure).cause, isA<StateError>());
    });
  });

  group('MxActionErrors', () {
    test('failureOf returns null for non-error states', () {
      expect(MxActionErrors.failureOf(const AsyncData(null)), isNull);
      expect(MxActionErrors.failureOf(const AsyncLoading()), isNull);
    });

    test('messageOf maps UnexpectedFailure to the safe copy', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final failure = UnexpectedFailure(
        cause: StateError('x'),
        stackTrace: StackTrace.current,
      );

      expect(
        MxActionErrors.messageOf(failure, l10n),
        l10n.somethingWentWrongMessage,
      );
    });
  });

  group('MxAsyncBuilder', () {
    Widget host(AsyncValue<String> value, {VoidCallback? onRetry}) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MxAsyncBuilder<String>(
            value: value,
            loadingLabel: 'Loading decks',
            errorTitle: 'Could not load decks',
            retryLabel: 'Retry',
            onRetry: onRetry,
            data: (context, value) => MxText(value),
          ),
        ),
      );
    }

    testWidgets('renders data', (tester) async {
      await tester.pumpWidget(host(const AsyncData('loaded')));
      expect(find.text('loaded'), findsOneWidget);
    });

    testWidgets('renders the announced spinner while loading', (tester) async {
      await tester.pumpWidget(host(const AsyncLoading()));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MxProgress), findsOneWidget);
      expect(find.bySemanticsLabel('Loading decks'), findsOneWidget);
    });

    testWidgets('renders the error banner with a working retry', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        host(AsyncError('boom', StackTrace.current), onRetry: () => retries++),
      );

      expect(find.byType(MxBanner), findsOneWidget);
      expect(find.text('Could not load decks'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('retains previous data while refreshing', (tester) async {
      var completer = Completer<String>();
      final provider = FutureProvider<String>((ref) => completer.future);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => MxAsyncBuilder<String>(
                  value: ref.watch(provider),
                  loadingLabel: 'Loading decks',
                  errorTitle: 'Could not load decks',
                  data: (context, value) => MxText(value),
                ),
              ),
            ),
          ),
        ),
      );

      completer.complete('previous');
      await tester.pump();
      expect(find.text('previous'), findsOneWidget);

      completer = Completer<String>();
      ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      ).invalidate(provider);
      await tester.pump();

      // Refreshing: retained data, no spinner.
      expect(find.text('previous'), findsOneWidget);
      expect(find.byType(MxProgress), findsNothing);
    });
  });

  group('listenMxAction', () {
    testWidgets('delivers one failure and one success per transition', (
      tester,
    ) async {
      final command = StateProvider<AsyncValue<void>>(
        (ref) => const AsyncData(null),
      );
      final failures = <AppFailure>[];
      var successes = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Consumer(
              builder: (context, ref, _) {
                listenMxAction(
                  ref,
                  command,
                  onFailure: failures.add,
                  onSuccess: () => successes++,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );

      container.read(command.notifier).state = const AsyncLoading();
      await tester.pump();
      container.read(command.notifier).state = AsyncError<void>(
        StateError('save failed'),
        StackTrace.current,
      );
      await tester.pump();
      expect(failures, hasLength(1));
      expect(failures.single, isA<UnexpectedFailure>());

      container.read(command.notifier).state = const AsyncLoading();
      await tester.pump();
      container.read(command.notifier).state = const AsyncData(null);
      await tester.pump();
      expect(successes, 1);
    });
  });
}
