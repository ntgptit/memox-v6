import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/router_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

void main() {
  group('color scheme mapping', () {
    for (final (name, theme, tokens) in <(String, ThemeData, AppColorTokens)>[
      ('light', AppTheme.light(), AppColors.light),
      ('dark', AppTheme.dark(), AppColors.dark),
    ]) {
      test('$name maps the documented token slots', () {
        final scheme = theme.colorScheme;

        expect(scheme.primary, tokens.primary);
        expect(scheme.onPrimary, tokens.onPrimary);
        expect(scheme.primaryContainer, tokens.primarySoft);
        expect(scheme.onPrimaryContainer, tokens.onPrimarySoft);
        expect(scheme.secondary, tokens.accent);
        expect(scheme.onSecondary, tokens.onAccent);
        expect(scheme.error, tokens.error);
        expect(scheme.surface, tokens.surface);
        expect(scheme.onSurface, tokens.text);
        expect(scheme.onSurfaceVariant, tokens.textSecondary);
        expect(scheme.outline, tokens.borderStrong);
        expect(scheme.outlineVariant, tokens.border);
        expect(scheme.scrim, tokens.overlay);
        expect(theme.scaffoldBackgroundColor, tokens.bg);
      });
    }
  });

  test('component themes follow the kit contracts', () {
    final theme = AppTheme.light();

    expect(theme.appBarTheme.toolbarHeight, AppSpacing.appbarHeight);
    expect(theme.appBarTheme.elevation, 0);
    expect(
      theme.floatingActionButtonTheme.backgroundColor,
      AppColors.light.accent,
    );
    expect(
      theme.snackBarTheme.backgroundColor,
      AppColors.light.snackbarNeutralBg,
    );
    expect(theme.snackBarTheme.actionTextColor, AppColors.light.accent);
    expect(theme.hoverColor, AppColors.light.stateHover);
    expect(theme.disabledColor, AppColors.light.stateDisabled);
    expect(theme.typography, isNotNull);
  });

  test('system UI overlay styles are theme-correct', () {
    final light = AppTheme.systemUiOverlayStyle(Brightness.light);
    expect(light.statusBarIconBrightness, Brightness.dark);
    expect(light.systemNavigationBarColor, AppColors.light.bg);

    final dark = AppTheme.systemUiOverlayStyle(Brightness.dark);
    expect(dark.statusBarIconBrightness, Brightness.light);
    expect(dark.systemNavigationBarColor, AppColors.dark.bg);
  });

  test('primary family is applied to the base text theme', () {
    final style = AppTheme.light().textTheme.bodyMedium!;

    expect(style.fontFamily, AppTypography.fontFamily);
  });

  testWidgets('app follows the platform brightness at runtime', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      buildRoot(
        overrides: [
          appRouterInstanceProvider.overrideWithValue(createAppRouter()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(context.colors.bg, AppColors.dark.bg);
    expect(Theme.of(context).brightness, Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    final relit = tester.element(find.byType(Scaffold).first);
    expect(relit.colors.bg, AppColors.light.bg);
  });
}
