import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';

/// Carries the semantic color tokens of the active theme (WBS 2.6).
///
/// Widgets read it through `context.colors`; only the theme layer
/// constructs it. Token-only — no Riverpod, no business state.
final class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({required this.tokens});

  final AppColorTokens tokens;

  static const AppColorsExtension light = AppColorsExtension(
    tokens: AppColors.light,
  );

  static const AppColorsExtension dark = AppColorsExtension(
    tokens: AppColors.dark,
  );

  @override
  AppColorsExtension copyWith({AppColorTokens? tokens}) =>
      AppColorsExtension(tokens: tokens ?? this.tokens);

  @override
  AppColorsExtension lerp(covariant AppColorsExtension? other, double t) {
    // Token values snap at the midpoint of a theme animation; the smooth
    // crossfade users perceive is owned by the Material color scheme lerp
    // in ThemeData (WBS 2.7).
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
