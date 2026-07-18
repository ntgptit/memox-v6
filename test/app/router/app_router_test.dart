import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

Widget _appWithRouter(GoRouter router) {
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  test('route constants are stable', () {
    expect(RoutePaths.home, '/');
    expect(RouteNames.home, 'home');
  });

  testWidgets('initial location renders the home placeholder', (tester) async {
    await tester.pumpWidget(_appWithRouter(createAppRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePlaceholderScreen), findsOneWidget);
    expect(find.text('MemoX Home'), findsOneWidget);
  });

  testWidgets('unknown location renders the localized not-found screen',
      (tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(_appWithRouter(router));
    await tester.pumpAndSettle();

    router.go('/definitely-not-a-route');
    await tester.pumpAndSettle();

    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    expect(find.text("This page doesn't exist."), findsOneWidget);
  });

  testWidgets('goHome extension returns to the home placeholder',
      (tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(_appWithRouter(router));
    await tester.pumpAndSettle();

    router.go('/definitely-not-a-route');
    await tester.pumpAndSettle();
    expect(find.byType(RouteNotFoundScreen), findsOneWidget);

    tester.element(find.byType(RouteNotFoundScreen)).goHome();
    await tester.pumpAndSettle();

    expect(find.byType(HomePlaceholderScreen), findsOneWidget);
  });

  testWidgets('home placeholder renders in Vietnamese', (tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(_appWithRouter(createAppRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ MemoX'), findsOneWidget);
  });
}
