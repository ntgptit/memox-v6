import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/tokens/app_elevations.dart';

/// Carries the themed shadow tokens of the active theme (WBS 2.6).
///
/// Widgets read it through `context.elevations`.
final class AppElevationsExtension
    extends ThemeExtension<AppElevationsExtension> {
  const AppElevationsExtension({required this.tokens});

  final AppElevationTokens tokens;

  static const AppElevationsExtension light = AppElevationsExtension(
    tokens: AppElevations.light,
  );

  static const AppElevationsExtension dark = AppElevationsExtension(
    tokens: AppElevations.dark,
  );

  @override
  AppElevationsExtension copyWith({AppElevationTokens? tokens}) =>
      AppElevationsExtension(tokens: tokens ?? this.tokens);

  @override
  AppElevationsExtension lerp(
    covariant AppElevationsExtension? other,
    double t,
  ) {
    // Discrete switch, same rationale as AppColorsExtension.lerp.
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
