// Icon tokens (WBS 2.5) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/icon-size.css.
// Parity gate: test/core/theme/motion_icon_css_parity_test.dart.

/// Icon glyph sizes plus the Material Symbols mapping contract.
///
/// Kit contract: glyphs are Material Symbols **Rounded** at the font's
/// default axes (FILL 0, wght 400, GRAD 0, optical size tracking the glyph
/// size) — the kit sets no `font-variation-settings` override. Icon sizes
/// that coincide with the type scale (20, 24) reuse
/// `AppTypography.fontSizeLg` / `fontSizeXl` instead of new tokens. The
/// Flutter glyph adapter (WBS 3.1 `Mx` icon) resolves symbol glyphs against
/// this contract; no emoji, no ad-hoc icon fonts.
abstract final class AppIconSizes {
  /// Material Symbols style used across the kit.
  static const String iconFontFamily = 'Material Symbols Rounded';

  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;

  /// icon-tile large glyph.
  static const double xl = 32;

  /// Every icon-size token keyed by its frozen CSS name.
  static const Map<String, double> byToken = <String, double>{
    '--memox-icon-size-sm': sm,
    '--memox-icon-size-md': md,
    '--memox-icon-size-lg': lg,
    '--memox-icon-size-xl': xl,
  };
}
