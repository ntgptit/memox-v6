import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';

/// WBS 3.9 — the shared async renderer. These cover the retained-composition
/// contract its doc claims: a failed *refresh* must not throw away the
/// snapshot already on screen.
///
/// The refreshing states are produced by refreshing a real provider rather
/// than hand-built: `AsyncValue.copyWithPrevious` is package-internal, and a
/// test that reached for it would be asserting against a shape Riverpod does
/// not promise to keep.
void main() {
  late bool shouldFail;

  final source = FutureProvider<String>((ref) async {
    if (shouldFail) throw StateError('boom');
    return 'loaded';
  });

  setUp(() => shouldFail = false);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String? staleLabel,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => MxAsyncBuilder<String>(
                value: ref.watch(source),
                staleLabel: staleLabel,
                errorTitle: 'Could not load',
                loadingLabel: 'Loading',
                data: (context, loaded) => Text(loaded),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> refreshFailing(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    shouldFail = true;
    await container
        .refresh(source.future)
        .then<void>((_) {}, onError: (Object _) {});
    await tester.pumpAndSettle();
  }

  testWidgets('a first-load error shows the error surface', (tester) async {
    shouldFail = true;
    await pump(tester, staleLabel: 'Stale');

    expect(find.text('Could not load'), findsOneWidget);
    expect(find.text('Stale'), findsNothing);
  });

  testWidgets('a failed refresh keeps the data under a stale notice', (
    tester,
  ) async {
    final container = await pump(tester, staleLabel: 'Stale');
    await refreshFailing(tester, container);

    expect(find.text('loaded'), findsOneWidget);
    expect(find.text('Stale'), findsOneWidget);
    expect(find.text('Could not load'), findsNothing);
  });

  // Opt-in: a screen whose provider only ever loads once wants the error, and
  // must not silently start showing old data instead.
  testWidgets('without a stale label a failed refresh still errors', (
    tester,
  ) async {
    final container = await pump(tester);
    await refreshFailing(tester, container);

    expect(find.text('Could not load'), findsOneWidget);
  });
}
