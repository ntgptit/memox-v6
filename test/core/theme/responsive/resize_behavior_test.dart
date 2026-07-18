import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/responsive/app_breakpoints.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';

void main() {
  test('pane rule follows the width contract per class', () {
    expect(
      AdaptiveLayout.of(ScreenClass.compactMobile).paneRule,
      PaneRule.single,
    );
    expect(AdaptiveLayout.of(ScreenClass.compact).paneRule, PaneRule.single);
    expect(
      AdaptiveLayout.of(ScreenClass.medium).paneRule,
      PaneRule.optionalTwoRegion,
    );
    expect(
      AdaptiveLayout.of(ScreenClass.expanded).paneRule,
      PaneRule.optionalListDetail,
    );
    expect(
      AdaptiveLayout.of(ScreenClass.large).paneRule,
      PaneRule.optionalListDetail,
    );
    expect(AdaptiveLayout.of(ScreenClass.large).centersCappedContent, isTrue);
    expect(
      AdaptiveLayout.of(ScreenClass.expanded).centersCappedContent,
      isFalse,
    );
  });

  test('component values are grounded in kit component contracts', () {
    expect(
      AdaptiveComponent.of(ScreenClass.compact).dialogMaxWidth,
      AppSizes.size5xl,
    );
  });

  testWidgets('app survives resizing across every class transition', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(390, 780);
    await tester.pumpWidget(buildRoot());
    await tester.pumpAndSettle();
    expect(find.byType(HomePlaceholderScreen), findsOneWidget);

    for (final size in const <Size>[
      Size(320, 780),
      Size(599, 900),
      Size(768, 1024),
      Size(1024, 800),
      Size(1440, 900),
      Size(390, 780),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(HomePlaceholderScreen));
      expect(tester.takeException(), isNull);
      expect(
        context.screenClass,
        ScreenClass.fromWidth(size.width),
        reason: 'width ${size.width}',
      );
      // Route/state survives the class transition.
      expect(find.byType(HomePlaceholderScreen), findsOneWidget);
    }
  });

  testWidgets('context.component resolves through MediaQuery', (tester) async {
    late AdaptiveComponent component;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 900)),
        child: Builder(
          builder: (context) {
            component = context.component;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(component.dialogMaxWidth, AppSizes.size5xl);
  });
}
