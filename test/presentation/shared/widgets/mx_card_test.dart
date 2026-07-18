import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_elevations.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

import '../../../support/l10n_fixtures.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

// `.last`: interactive cards nest the surface inside MxTappable, whose
// focus-ring AnimatedContainer comes first in the tree.
AnimatedContainer _surface(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).last);

BoxDecoration _decoration(WidgetTester tester) =>
    _surface(tester).decoration! as BoxDecoration;

void main() {
  testWidgets('elevated card uses surface, card shadow and md padding', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MxCard(child: MxText('content'))));

    final decoration = _decoration(tester);
    expect(decoration.color, AppColors.light.surface);
    expect(decoration.boxShadow, AppElevations.light.shadowCard);
    expect(_surface(tester).padding, const EdgeInsets.all(AppSpacing.space6));
  });

  testWidgets('flat card swaps the shadow for a hairline border', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MxCard(variant: MxCardVariant.flat, child: MxText('content')),
      ),
    );

    final decoration = _decoration(tester);
    expect(decoration.boxShadow, isEmpty);
    expect(decoration.border!.top.color, AppColors.light.border);
    expect(decoration.border!.top.width, AppStrokes.hairline);
  });

  testWidgets('primary card fills brand and recolors child text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MxCard(
          variant: MxCardVariant.primary,
          child: Text('142 cards due'),
        ),
      ),
    );

    expect(_decoration(tester).color, AppColors.light.primary);
    expect(_decoration(tester).boxShadow, AppElevations.light.shadowFab);
    final style = DefaultTextStyle.of(
      tester.element(find.text('142 cards due')),
    ).style;
    expect(style.color, AppColors.light.onPrimary);
  });

  testWidgets('primary-soft and muted grounds match the kit', (tester) async {
    await tester.pumpWidget(
      _host(
        const MxCard(variant: MxCardVariant.primarySoft, child: MxText('tint')),
      ),
    );
    expect(_decoration(tester).color, AppColors.light.primarySoft);

    await tester.pumpWidget(
      _host(const MxCard(variant: MxCardVariant.muted, child: MxText('muted'))),
    );
    expect(_decoration(tester).color, AppColors.light.surfaceMuted);
    expect(_decoration(tester).boxShadow, isEmpty);
  });

  testWidgets('sm padding tightens to space-4', (tester) async {
    await tester.pumpWidget(
      _host(const MxCard(padding: MxCardPadding.sm, child: MxText('dense'))),
    );

    expect(_surface(tester).padding, const EdgeInsets.all(AppSpacing.space4));
  });

  testWidgets('static card exposes no tap surface', (tester) async {
    await tester.pumpWidget(_host(const MxCard(child: MxText('static'))));

    expect(find.byType(MxTappable), findsNothing);
  });

  testWidgets('interactive card taps, lifts on hover and scales on press', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        MxCard(
          onTap: () => taps++,
          semanticLabel: 'Open due cards',
          child: const MxText('due'),
        ),
      ),
    );

    await tester.tap(find.byType(MxCard));
    expect(taps, 1);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MxCard)));
    await tester.pumpAndSettle();
    expect(_decoration(tester).boxShadow, AppElevations.light.shadowLg);

    final press = await tester.startGesture(
      tester.getCenter(find.byType(MxCard)),
    );
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 0.985);
    await press.up();
  });

  testWidgets('long content wraps without clipping', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 780);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(MxCard(child: MxText(expansionFixtureText))));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Benachrichtigung'), findsOneWidget);
  });
}
