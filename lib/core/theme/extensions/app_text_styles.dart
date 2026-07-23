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

  // The kit `.app` shell sets the inherited defaults (line-height
  // normal, letter-spacing 0). They are EXPLICIT here because merged
  // Material defaults (bodyMedium: +0.25 tracking, 1.43 height) would
  // otherwise leak into every role field the kit leaves at default.
  static const TextStyle _base = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    letterSpacing: AppTypography.letterSpacingNormalEm,
    height: AppTypography.lineHeightNormal,
  );

  // Display and headline carry the kit's tight tracking
  // (`type-scale.html`: letter-spacing -0.02em on both hero roles).
  TextStyle get display => _base.copyWith(
    fontSize: AppTypography.fontSize3xl,
    fontWeight: AppTypography.fontWeightExtrabold,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingTightEm,
      AppTypography.fontSize3xl,
    ),
  );

  TextStyle get headline => _base.copyWith(
    fontSize: AppTypography.fontSize2xl,
    fontWeight: AppTypography.fontWeightExtrabold,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingTightEm,
      AppTypography.fontSize2xl,
    ),
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

  /// Bottom-nav label role (kit `.bottom-nav__item`: xs/semibold; active
  /// items raise to bold via `copyWith`).
  TextStyle get navLabel => _base.copyWith(
    fontSize: AppTypography.fontSizeXs,
    fontWeight: AppTypography.fontWeightSemibold,
  );

  /// Bold weight accessor for active states composed over other roles.
  FontWeight get boldWeight => AppTypography.fontWeightBold;

  /// Kit line-height tokens (`--memox-line-height-*`) for copy whose
  /// spec calls out a reading rhythm; consumed via `MxText.lineHeight`.
  double get lineHeightNone => AppTypography.lineHeightNone;
  double get lineHeightTight => AppTypography.lineHeightTight;
  double get lineHeightSnug => AppTypography.lineHeightSnug;
  double get lineHeightNormal => AppTypography.lineHeightNormal;
  double get lineHeightRelaxed => AppTypography.lineHeightRelaxed;

  /// App-bar title role (kit `.cappbar__title`: lg/semibold/tight —
  /// every bar variant shares it).
  TextStyle get appBarTitle => _base.copyWith(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.fontWeightSemibold,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingTightEm,
      AppTypography.fontSizeLg,
    ),
  );

  /// Empty-state title role (kit `EmptyState` helper: lg/extrabold/tight).
  TextStyle get emptyStateTitle => _base.copyWith(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.fontWeightExtrabold,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingTightEm,
      AppTypography.fontSizeLg,
    ),
  );

  /// Section-header title role (kit `.section-head__title`: md/bold/tight).
  TextStyle get sectionTitle => _base.copyWith(
    fontSize: AppTypography.fontSizeMd,
    fontWeight: AppTypography.fontWeightBold,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingTightEm,
      AppTypography.fontSizeMd,
    ),
  );

  /// Section/field caption role (kit `SectionLabel` helper:
  /// sm/bold/wide; consumers apply the secondary color).
  TextStyle get sectionLabel => _base.copyWith(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightBold,
    letterSpacing: AppTypography.letterSpacingFor(
      AppTypography.letterSpacingWideEm,
      AppTypography.fontSizeSm,
    ),
  );

  /// Field-group label role (kit `.field-group__label`: sm/semibold).
  TextStyle get fieldLabel => _base.copyWith(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightSemibold,
  );

  /// Breadcrumb ancestor-crumb role (kit `.breadcrumb__crumb`: sm/medium;
  /// consumers apply the secondary color).
  TextStyle get breadcrumbCrumb => _base.copyWith(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightMedium,
  );

  /// Breadcrumb current-page role (kit `.breadcrumb__current`: sm/semibold;
  /// consumers apply the primary text color).
  TextStyle get breadcrumbCurrent => _base.copyWith(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightSemibold,
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
