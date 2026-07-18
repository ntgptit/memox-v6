// Stroke / border-width tokens (WBS 2.4) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/stroke.css.
// Parity gate: test/core/theme/dimension_css_parity_test.dart.

/// Border-width scale; theme-independent by kit contract.
abstract final class AppStrokes {
  /// Default borders and dividers.
  static const double hairline = 1;

  /// Selected / state / active borders.
  static const double emphasis = 2;

  /// Focus and selection rings.
  static const double focus = 3;

  /// Outline buttons / switch track inset.
  static const double mid = 1.5;

  /// Avatar ring outer band.
  static const double bold = 4;

  /// Every stroke token keyed by its frozen CSS name.
  static const Map<String, double> byToken = <String, double>{
    '--memox-stroke-hairline': hairline,
    '--memox-stroke-emphasis': emphasis,
    '--memox-stroke-focus': focus,
    '--memox-stroke-mid': mid,
    '--memox-stroke-bold': bold,
  };
}
