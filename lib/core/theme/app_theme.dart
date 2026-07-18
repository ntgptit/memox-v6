import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox_v6/core/theme/extensions/app_colors_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_elevations_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_text_styles.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

/// Material 3 theme assembly over the token layer (WBS 2.7).
///
/// Semantic-token → M3 color-scheme mapping (documented contract; the
/// `Mx*` layer reads tokens directly via `context.colors`, this scheme
/// exists so plain Material internals render on-brand):
///
/// | M3 slot | Token |
/// | --- | --- |
/// | primary / onPrimary | `primary` / `on-primary` |
/// | primaryContainer / onPrimaryContainer | `primary-soft` / `on-primary-soft` |
/// | secondary / onSecondary | `accent` / `on-accent` |
/// | secondaryContainer / onSecondaryContainer | `accent-soft` / `text` |
/// | tertiary family | `info` family |
/// | error family | `error` family |
/// | surface / onSurface / onSurfaceVariant | `surface` / `text` / `text-secondary` |
/// | surfaceContainerLow / High / Dim | `surface-muted` / `surface-raised` / `surface-sunken` |
/// | outline / outlineVariant | `border-strong` / `border` |
/// | scrim | `overlay` |
///
/// Theme definitions only — no Riverpod (guard
/// `memox.design_system.theme_file_no_riverpod`).
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  /// Status/navigation bar appearance for the given theme.
  static SystemUiOverlayStyle systemUiOverlayStyle(Brightness brightness) {
    final tokens = brightness == Brightness.light
        ? AppColors.light
        : AppColors.dark;
    final iconBrightness = brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: brightness,
      systemNavigationBarColor: tokens.bg,
      systemNavigationBarIconBrightness: iconBrightness,
    );
  }

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    final inverse = brightness == Brightness.light
        ? AppColors.dark
        : AppColors.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primarySoft,
      onPrimaryContainer: tokens.onPrimarySoft,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      secondaryContainer: tokens.accentSoft,
      onSecondaryContainer: tokens.text,
      tertiary: tokens.info,
      onTertiary: tokens.onInfo,
      tertiaryContainer: tokens.infoSoft,
      onTertiaryContainer: tokens.onInfoSoft,
      error: tokens.error,
      onError: tokens.onError,
      errorContainer: tokens.errorSoft,
      onErrorContainer: tokens.onErrorSoft,
      surface: tokens.surface,
      onSurface: tokens.text,
      onSurfaceVariant: tokens.textSecondary,
      surfaceContainerLowest: tokens.surface,
      surfaceContainerLow: tokens.surfaceMuted,
      surfaceContainer: tokens.surfaceMuted,
      surfaceContainerHigh: tokens.surfaceRaised,
      surfaceContainerHighest: tokens.surfaceRaised,
      surfaceDim: tokens.surfaceSunken,
      surfaceBright: tokens.surface,
      outline: tokens.borderStrong,
      outlineVariant: tokens.border,
      shadow: const Color(0xFF000000),
      scrim: tokens.overlay,
      inverseSurface: inverse.surface,
      onInverseSurface: inverse.text,
      inversePrimary: inverse.primaryStrong,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      scaffoldBackgroundColor: tokens.bg,
      canvasColor: tokens.bg,
      dividerColor: tokens.divider,
      focusColor: tokens.focusRing,
      hoverColor: tokens.stateHover,
      highlightColor: tokens.statePressed,
      splashColor: tokens.statePressed,
      disabledColor: tokens.stateDisabled,
      appBarTheme: AppBarTheme(
        toolbarHeight: AppSpacing.appbarHeight,
        backgroundColor: tokens.bg,
        foregroundColor: tokens.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemUiOverlayStyle(brightness),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: AppStrokes.hairline,
        space: AppStrokes.hairline,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.onAccent,
        sizeConstraints: BoxConstraints.tightFor(
          width: AppSpacing.fabSize,
          height: AppSpacing.fabSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.snackbarNeutralBg,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.fontSizeBase,
          color: tokens.snackbarNeutralText,
        ),
        actionTextColor: tokens.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusControl),
          side: BorderSide(
            color: tokens.snackbarNeutralBorder,
            width: AppStrokes.hairline,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.surfaceSunken,
        circularTrackColor: tokens.surfaceSunken,
      ),
      extensions: [
        brightness == Brightness.light
            ? AppColorsExtension.light
            : AppColorsExtension.dark,
        brightness == Brightness.light
            ? AppElevationsExtension.light
            : AppElevationsExtension.dark,
        const AppTextStyles(),
      ],
    );
  }
}
