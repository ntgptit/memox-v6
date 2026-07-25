import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/today/screens/today_screen.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_bottom_nav.dart';

Widget _appWithRouter(GoRouter router) {
  // The shell renders kit chrome (`MxBottomNav`) on every root destination, so
  // the harness must carry the app theme extensions. Home is the async Today
  // entry (WBS 5.7.2), so pin a resolved projection so it settles.
  return ProviderScope(
    overrides: [
      todayProjectionProvider.overrideWith(
        (ref) async => const TodayProjection(
          primaryAction: TodayPrimaryAction.caughtUp,
          dueCount: 0,
        ),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  test('route constants are stable', () {
    expect(RoutePaths.home, '/');
    expect(RouteNames.home, 'home');
  });

  testWidgets('initial location renders the Today home', (tester) async {
    await tester.pumpWidget(_appWithRouter(createAppRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    // The Today title also labels the nav tab.
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('unknown location renders the localized not-found screen', (
    tester,
  ) async {
    final router = createAppRouter();
    await tester.pumpWidget(_appWithRouter(router));
    await tester.pumpAndSettle();

    router.go('/definitely-not-a-route');
    await tester.pumpAndSettle();

    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    expect(find.text("This page doesn't exist."), findsOneWidget);
  });

  testWidgets('not-found offers an in-app recovery back to home', (
    tester,
  ) async {
    // A stale/unknown URL must never strand the user: the contract
    // (navigation README) requires a typed recovery destination, not
    // reliance on browser/system Back.
    final router = createAppRouter();
    await tester.pumpWidget(_appWithRouter(router));
    await tester.pumpAndSettle();

    router.go('/definitely-not-a-route');
    await tester.pumpAndSettle();
    expect(find.byType(RouteNotFoundScreen), findsOneWidget);

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(find.byType(RouteNotFoundScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('goHome extension returns to the home placeholder', (
    tester,
  ) async {
    final router = createAppRouter();
    await tester.pumpWidget(_appWithRouter(router));
    await tester.pumpAndSettle();

    router.go('/definitely-not-a-route');
    await tester.pumpAndSettle();
    expect(find.byType(RouteNotFoundScreen), findsOneWidget);

    tester.element(find.byType(RouteNotFoundScreen)).goHome();
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
  });

  // Regression: the root destinations were four independent top-level
  // routes and only Library built the tab bar, so `goStats()`/`goProfile()`
  // replaced the stack with a screen that had no tab bar and nothing to
  // pop back to — a dead end. The tab bar belongs to the shell.
  for (final (name, path) in <(String, String)>[
    ('home', RoutePaths.home),
    ('stats', RoutePaths.stats),
    ('profile', RoutePaths.profile),
  ]) {
    testWidgets('$name root destination keeps the persistent tab bar', (
      tester,
    ) async {
      final router = createAppRouter();
      await tester.pumpWidget(_appWithRouter(router));
      await tester.pumpAndSettle();

      router.go(path);
      await tester.pumpAndSettle();

      expect(find.byType(MxBottomNav), findsOneWidget);
    });
  }

  testWidgets('tapping a root destination switches branch, never strands', (
    tester,
  ) async {
    final router = createAppRouter();
    await tester.pumpWidget(_appWithRouter(router));
    await tester.pumpAndSettle();

    tester.element(find.byType(TodayScreen)).goStats();
    await tester.pumpAndSettle();
    expect(find.byType(StatsPlaceholderScreen), findsOneWidget);

    // The tab bar is the way back out; Stats must not be terminal.
    final nav = tester.widget<MxBottomNav>(find.byType(MxBottomNav));
    nav.onChanged(RouteNames.home);
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('Today home renders in Vietnamese', (tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(_appWithRouter(createAppRouter()));
    await tester.pumpAndSettle();

    // The Today title also labels the nav tab.
    expect(find.text('Hôm nay'), findsWidgets);
  });
}
