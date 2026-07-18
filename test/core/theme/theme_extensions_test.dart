import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/extensions/app_colors_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_elevations_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_text_styles.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_elevations.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

ThemeData _theme(Brightness brightness) => ThemeData(
  brightness: brightness,
  extensions: <ThemeExtension<dynamic>>[
    brightness == Brightness.light
        ? AppColorsExtension.light
        : AppColorsExtension.dark,
    brightness == Brightness.light
        ? AppElevationsExtension.light
        : AppElevationsExtension.dark,
    const AppTextStyles(),
  ],
);

Future<BuildContext> _pump(WidgetTester tester, Brightness brightness) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme(brightness),
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('context.colors resolves the light token set', (tester) async {
    final context = await _pump(tester, Brightness.light);

    expect(context.colors.bg, AppColors.light.bg);
    expect(context.colors.accent, AppColors.light.accent);
  });

  testWidgets('context.colors resolves the dark token set', (tester) async {
    final context = await _pump(tester, Brightness.dark);

    expect(context.colors.bg, AppColors.dark.bg);
    expect(context.colors.focusRing, AppColors.dark.focusRing);
  });

  testWidgets('context.elevations resolves per theme', (tester) async {
    final light = await _pump(tester, Brightness.light);
    expect(light.elevations.shadowCard, AppElevations.light.shadowCard);

    final dark = await _pump(tester, Brightness.dark);
    expect(dark.elevations.shadowCard, AppElevations.dark.shadowCard);
  });

  testWidgets('context.textStyles exposes the kit type-scale roles', (
    tester,
  ) async {
    final context = await _pump(tester, Brightness.light);
    final styles = context.textStyles;

    // Exactly the guideline table: size token / weight.
    expect(styles.display.fontSize, AppTypography.fontSize3xl);
    expect(styles.display.fontWeight, AppTypography.fontWeightExtrabold);
    expect(styles.headline.fontSize, AppTypography.fontSize2xl);
    expect(styles.headline.fontWeight, AppTypography.fontWeightExtrabold);
    expect(styles.title.fontSize, AppTypography.fontSizeXl);
    expect(styles.title.fontWeight, AppTypography.fontWeightBold);
    expect(styles.subtitle.fontSize, AppTypography.fontSizeLg);
    expect(styles.subtitle.fontWeight, AppTypography.fontWeightBold);
    expect(styles.bodyLarge.fontSize, AppTypography.fontSizeMd);
    expect(styles.bodyLarge.fontWeight, AppTypography.fontWeightSemibold);
    expect(styles.body.fontSize, AppTypography.fontSizeBase);
    expect(styles.body.fontWeight, AppTypography.fontWeightRegular);
    expect(styles.caption.fontSize, AppTypography.fontSizeSm);
    expect(styles.overline.fontSize, AppTypography.fontSizeXs);
    expect(
      styles.overline.letterSpacing,
      AppTypography.letterSpacingFor(
        AppTypography.letterSpacingCapsEm,
        AppTypography.fontSizeXs,
      ),
    );
    expect(styles.body.fontFamily, AppTypography.fontFamily);
  });

  test('lerp is a discrete midpoint switch', () {
    const light = AppColorsExtension.light;
    const dark = AppColorsExtension.dark;

    expect(light.lerp(dark, 0.49), same(light));
    expect(light.lerp(dark, 0.51), same(dark));
    expect(light.lerp(null, 0.9), same(light));

    const lightElevations = AppElevationsExtension.light;
    expect(
      lightElevations.lerp(AppElevationsExtension.dark, 0.6),
      same(AppElevationsExtension.dark),
    );
  });
}
