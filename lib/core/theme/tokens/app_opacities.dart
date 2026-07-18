// GENERATED from the design kit — do not edit by hand.
//
// Source: docs/design/MemoX Design System_v4/tokens/colors.css (+ opacity.css)
// Regenerate: node tool/design/color_tokens.mjs --write
// Parity gate: test/core/theme/token_css_parity_test.dart re-parses the CSS
// on every verifier run and fails on any value or coverage drift.
// Token NAMES are a frozen contract (additive-only); values follow the kit.

/// Opacity scale (WBS 2.2); theme-independent.
abstract final class AppOpacities {
  /// `--memox-opacity-disabled`
  static const double opacityDisabled = 0.45;

  /// `--memox-opacity-half`
  static const double opacityHalf = 0.5;

  /// `--memox-opacity-label`
  static const double opacityLabel = 0.9;

  /// `--memox-opacity-label-soft`
  static const double opacityLabelSoft = 0.85;

  /// `--memox-opacity-muted`
  static const double opacityMuted = 0.55;

  /// Every opacity token keyed by its frozen CSS name.
  static const Map<String, double> byToken = <String, double>{
    '--memox-opacity-disabled': opacityDisabled,
    '--memox-opacity-half': opacityHalf,
    '--memox-opacity-label': opacityLabel,
    '--memox-opacity-label-soft': opacityLabelSoft,
    '--memox-opacity-muted': opacityMuted,
  };
}
