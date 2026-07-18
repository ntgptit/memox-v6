// Radius tokens (WBS 2.4) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/radius.css.
// Parity gate: test/core/theme/dimension_css_parity_test.dart.

/// Corner radius scale plus role aliases.
abstract final class AppRadii {
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radius2xl = 28;

  // Role aliases.
  static const double radiusCard = 20;
  static const double radiusTile = 16;
  static const double radiusControl = 12;
  static const double radiusField = 14;
  static const double radiusChip = 999;
  static const double radiusPill = 999;
  static const double radiusFull = 9999;

  /// Every radius token keyed by its frozen CSS name.
  static const Map<String, double> byToken = <String, double>{
    '--memox-radius-xs': radiusXs,
    '--memox-radius-sm': radiusSm,
    '--memox-radius-md': radiusMd,
    '--memox-radius-lg': radiusLg,
    '--memox-radius-xl': radiusXl,
    '--memox-radius-2xl': radius2xl,
    '--memox-radius-card': radiusCard,
    '--memox-radius-tile': radiusTile,
    '--memox-radius-control': radiusControl,
    '--memox-radius-field': radiusField,
    '--memox-radius-chip': radiusChip,
    '--memox-radius-pill': radiusPill,
    '--memox-radius-full': radiusFull,
  };
}
