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
    await tester.pumpAndSettle();

    expect(find.text('MemoX Home'), findsOneWidget);
    expect(find.text('MemoX'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ MemoX'), findsOneWidget);
  });
}
