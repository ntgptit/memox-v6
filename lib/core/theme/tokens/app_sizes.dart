// Element size tokens (WBS 2.4) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/size.css.
// Parity gate: test/core/theme/dimension_css_parity_test.dart.

/// Fixed-size element scale (avatars, rings, tiles, illustration boxes,
/// modal max-widths). Fluid layout stays out of this scale.
abstract final class AppSizes {
  static const double size3xs = 4;
  static const double size2xs = 8;
  static const double sizeXs = 16;
  static const double sizeSm = 40;
  static const double sizeMd = 56;
  static const double sizeLg = 74;
  static const double sizeXl = 96;
  static const double size2xl = 120;
  static const double size3xl = 220;
  static const double size4xl = 280;
  static const double size5xl = 320;

  /// Every size token keyed by its frozen CSS name.
  static const Map<String, double> byToken = <String, double>{
    '--memox-size-3xs': size3xs,
    '--memox-size-2xs': size2xs,
    '--memox-size-xs': sizeXs,
    '--memox-size-sm': sizeSm,
    '--memox-size-md': sizeMd,
    '--memox-size-lg': sizeLg,
    '--memox-size-xl': sizeXl,
    '--memox-size-2xl': size2xl,
    '--memox-size-3xl': size3xl,
    '--memox-size-4xl': size4xl,
    '--memox-size-5xl': size5xl,
  };
}
