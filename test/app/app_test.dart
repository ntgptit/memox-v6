import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/router_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';

void main() {
  testWidgets('root renders the localized home in English', (tester) async {
    await tester.pumpWidget(
      buildRoot(
        overrides: [
          appRouterInstanceProvider.overrideWithValue(createAppRouter()),
        ],
      ),
    );
    // Home is the Today entry (WBS 5.7.2). Its body loads asynchronously behind
    // an animated spinner, so settle on the app bar rather than pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('root renders the localized home in Vietnamese', (tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      buildRoot(
        overrides: [
          appRouterInstanceProvider.overrideWithValue(createAppRouter()),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Hôm nay'), findsWidgets);
  });
}
