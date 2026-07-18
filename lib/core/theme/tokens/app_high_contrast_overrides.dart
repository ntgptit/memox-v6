// High-contrast profile tokens (WBS 2.9) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/high-contrast.css —
// an additive, opt-in third profile (KIT-08-06/KIT-39-05) that raises the
// contrast of the lowest-ratio roles (hairline borders, secondary/tertiary
// text, focus ring) over the light/dark bases.
//
// RELEASE STATUS — deferred, no runtime support claim: per the accepted
// v1 scope (WBS 0.6 / design SCOPE.md) the app does NOT branch on
// `MediaQuery.highContrast` and ships no high-contrast setting. This file
// keeps the token layer complete and merge-ready so a future scope
// decision can wire the profile without re-deriving values.
// Parity gate: test/core/theme/high_contrast_css_parity_test.dart.

import 'dart:ui';

import 'package:memox_v6/core/theme/tokens/app_colors.dart';

/// The six roles the high-contrast profile overrides.
final class HighContrastOverrides {
  const HighContrastOverrides({
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textSecondary,
    required this.textTertiary,
    required this.focusRing,
  });

  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color textSecondary;
  final Color textTertiary;
  final Color focusRing;

  /// Overrides keyed by frozen CSS name (parity).
  Map<String, Color> get byToken => <String, Color>{
    '--memox-border': border,
    '--memox-border-strong': borderStrong,
    '--memox-divider': divider,
    '--memox-text-secondary': textSecondary,
    '--memox-text-tertiary': textTertiary,
    '--memox-focus-ring': focusRing,
  };
}

/// Kit high-contrast values layered over each base theme.
abstract final class AppHighContrastOverrides {
  /// `[data-hc='true']` over the light base.
  static const HighContrastOverrides light = HighContrastOverrides(
    border: Color.fromRGBO(28, 24, 45, 0.38),
    borderStrong: Color.fromRGBO(28, 24, 45, 0.55),
    divider: Color.fromRGBO(28, 24, 45, 0.28),
    textSecondary: Color(0xFF34324A),
    textTertiary: Color(0xFF34324A),
    focusRing: Color(0xFF241A4D),
  );

  /// `[data-theme='dark'][data-hc='true']` over the dark base.
  static const HighContrastOverrides dark = HighContrastOverrides(
    border: Color.fromRGBO(255, 255, 255, 0.42),
    borderStrong: Color.fromRGBO(255, 255, 255, 0.62),
    divider: Color.fromRGBO(255, 255, 255, 0.32),
    textSecondary: Color(0xFFECE9F7),
    textTertiary: Color(0xFFECE9F7),
    focusRing: Color(0xFFE4DEFF),
  );
}

/// Merges a base theme with its high-contrast overrides; all other roles
/// stay untouched (the kit profile is additive by design).
AppColorTokens applyHighContrast(
  AppColorTokens base,
  HighContrastOverrides overrides,
) {
  return base.copyWith(
    border: overrides.border,
    borderStrong: overrides.borderStrong,
    divider: overrides.divider,
    textSecondary: overrides.textSecondary,
    textTertiary: overrides.textTertiary,
    focusRing: overrides.focusRing,
  );
}
