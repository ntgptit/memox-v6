import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

/// Semantic text roles (WBS 2.6), exactly as the kit's type-scale guideline
/// documents them (`guidelines/type-scale.html`):
///
/// | Role       | Size token | Weight |
/// | ---------- | ---------- | ------ |
/// | display    | 3xl (38)   | 800    |
/// | headline   | 2xl (30)   | 800    |
/// | title      | xl (24)    | 700    |
/// | subtitle   | lg (20)    | 700    |
/// | bodyLarge  | md (17)    | 600    |
/// | body       | base (15)  | 400    |
/// | caption    | sm (13)    | 400    |
/// | overline   | xs (12)    | 400 + caps tracking |
///
/// Roles carry only what the kit specifies (family, size, weight, overline
/// caps tracking). Color is applied by the consumer from `context.colors`;
/// line heights are set per component spec. `MxText` (WBS 3.1) is the
/// feature-facing API over these roles.
final class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles();

  static const TextStyle _base = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
  );

  TextStyle get display => _base.copyWith(
    fontSize: AppTypography.fontSize3xl,
    fontWeight: AppTypography.fontWeightExtrabold,
  );

  TextStyle get headline => _base.copyWith(
    fontSize: AppTypography.fontSize2xl,
    fontWeight: AppTypography.fontWeightExtrabold,
  );

  TextStyle get title => _base.copyWith(
    fontSize: AppTypography.fontSizeXl,
    fontWeight: AppTypography.fontWeightBold,
  );

  TextStyle get subtitle => _base.copyWith(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.fontWeightBold,
  );

  TextStyle get bodyLarge => _base.copyWith(
    fontSize: AppTypography.fontSizeMd,
    fontWeight: AppTypography.fontWeightSemibold,
  );

  TextStyle get body => _base.copyWith(
    fontSize: AppTypography.fontSizeBase,
    fontWeight: AppTypography.fontWeightRegular,
  );

  TextStyle get caption => _base.copyWith(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightRegular,
  );

  TextStyle get overline => _base.copyWith(
    fontSize: AppTypography.fontSizeXs,
    fontWeight: AppTypography.fontWeightRegular,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingCapsEm,
      AppTypography.fontSizeXs,
    ),
  );

  /// Button label roles (kit `.btn`: bold at sm/base/md sizes).
  TextStyle get buttonSm => _base.copyWith(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightBold,
  );

  TextStyle get button => _base.copyWith(
    fontSize: AppTypography.fontSizeBase,
    fontWeight: AppTypography.fontWeightBold,
  );

  TextStyle get buttonLg => _base.copyWith(
    fontSize: AppTypography.fontSizeMd,
    fontWeight: AppTypography.fontWeightBold,
  );

  @override
  AppTextStyles copyWith() => const AppTextStyles();

  @override
  AppTextStyles lerp(covariant AppTextStyles? other, double t) => this;
}
