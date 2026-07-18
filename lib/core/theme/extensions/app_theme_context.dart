import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_colors_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_elevations_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_text_styles.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_elevations.dart';

/// Feature-facing theme accessors (WBS 2.6).
///
/// Features never import token source files (guard
/// `memox.design_system.no_theme_token_imports`); they read the active
/// theme's contracts through these getters. Responsive dimension accessors
/// (`context.spacing`, `context.layout`, …) are added by WBS 2.8.
extension AppThemeContext on BuildContext {
  /// Semantic colors of the active theme.
  AppColorTokens get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.tokens;

  /// Themed shadow tokens of the active theme.
  AppElevationTokens get elevations =>
      Theme.of(this).extension<AppElevationsExtension>()!.tokens;

  /// Semantic text roles (color applied by the consumer from [colors]).
  AppTextStyles get textStyles => Theme.of(this).extension<AppTextStyles>()!;
}
