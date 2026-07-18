import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

BoxDecoration _fillOf(WidgetTester tester) {
  final ink = tester.widget<Ink>(find.byType(Ink));
  return ink.decoration! as BoxDecoration;
}

void main() {
  testWidgets('primary fills with the brand pair and fires onPressed', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      _host(MxButton(onPressed: () => pressed++, label: 'Start review')),
    );

    expect(_fillOf(tester).color, AppColors.light.primary);
    final text = tester.widget<Text>(find.text('Start review'));
    expect(text.style?.color, AppColors.light.onPrimary);
    expect(text.style?.fontWeight, AppTypography.fontWeightBold);

    await tester.tap(find.byType(MxButton));
    expect(pressed, 1);
  });

  testWidgets('secondary is the tonal pair', (tester) async {
    await tester.pumpWidget(
      _host(
        MxButton(
          onPressed: () {},
          label: 'Edit',
          variant: MxButtonVariant.secondary,
        ),
      ),
    );

    expect(_fillOf(tester).color, AppColors.light.primarySoft);
    final text = tester.widget<Text>(find.text('Edit'));
    expect(text.style?.color, AppColors.light.onPrimarySoft);
  });

  testWidgets('outline draws the stroke-mid border on a transparent fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        MxButton(
          onPressed: () {},
          label: 'Edit deck',
          variant: MxButtonVariant.outline,
        ),
      ),
    );

    final decoration = _fillOf(tester);
    expect(decoration.color?.a, 0);
    expect(decoration.border!.top.color, AppColors.light.borderStrong);
    expect(decoration.border!.top.width, AppStrokes.mid);
    final text = tester.widget<Text>(find.text('Edit deck'));
    expect(text.style?.color, AppColors.light.text);
  });

  testWidgets('ghost uses accent text and a hairline border', (tester) async {
    await tester.pumpWidget(
      _host(
        MxButton(
          onPressed: () {},
          label: 'Skip',
          variant: MxButtonVariant.ghost,
        ),
      ),
    );

    final decoration = _fillOf(tester);
    expect(decoration.border!.top.width, AppStrokes.hairline);
    final text = tester.widget<Text>(find.text('Skip'));
    expect(text.style?.color, AppColors.light.accent);
  });

  testWidgets('danger recolors to the error pair', (tester) async {
    await tester.pumpWidget(
      _host(MxButton(onPressed: () {}, label: 'Delete', danger: true)),
    );

    expect(_fillOf(tester).color, AppColors.light.error);
    final text = tester.widget<Text>(find.text('Delete'));
    expect(text.style?.color, AppColors.light.onError);
  });

  testWidgets('disabled dims to opacity-disabled and ignores taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MxButton(onPressed: null, label: 'Save')),
    );

    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byType(Ink), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, AppOpacities.opacityDisabled);

    await tester.tap(find.byType(MxButton), warnIfMissed: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sm keeps the 48px hit target around a 40px visual', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(MxButton(onPressed: () {}, label: 'Small', size: MxButtonSize.sm)),
    );

    expect(tester.getSize(find.byType(Ink)).height, AppSizes.sizeSm);
    expect(
      tester.getSize(find.byType(MxButton)).height,
      greaterThanOrEqualTo(AppSpacing.touchMin),
    );
  });

  testWidgets('lg raises the visual to size-md', (tester) async {
    await tester.pumpWidget(
      _host(MxButton(onPressed: () {}, label: 'Large', size: MxButtonSize.lg)),
    );

    expect(tester.getSize(find.byType(Ink)).height, AppSizes.sizeMd);
  });

  testWidgets('block fills the available width', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 300,
          child: MxButton(onPressed: () {}, label: 'Continue', block: true),
        ),
      ),
    );

    // MxTappable reserves the focus-ring stroke on each side so focusing
    // never shifts layout.
    expect(tester.getSize(find.byType(Ink)).width, 300 - 2 * AppStrokes.focus);
  });

  testWidgets('leading icon renders at font-size-lg in the label color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        MxButton(onPressed: () {}, label: 'Play', icon: Symbols.play_arrow),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, AppTypography.fontSizeLg);
    expect(icon.color, AppColors.light.onPrimary);
  });

  testWidgets('hover swaps the primary fill to primary-strong', (tester) async {
    await tester.pumpWidget(
      _host(MxButton(onPressed: () {}, label: 'Hover me')),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MxButton)));
    await tester.pumpAndSettle();

    expect(_fillOf(tester).color, AppColors.light.primaryStrong);
  });
}
