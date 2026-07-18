// Motion tokens (WBS 2.5) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/motion.css.
// Theme-independent. Parity gate:
// test/core/theme/motion_icon_css_parity_test.dart.

import 'package:flutter/animation.dart';

/// Duration + easing scale. Durations scale with the size of the moving
/// surface; easings follow the standard / enter (decelerate) / exit
/// (accelerate) split.
abstract final class AppMotion {
  /// Micro feedback: switch, ripple, press.
  static const Duration durationInstant = Duration(milliseconds: 80);

  /// Small surfaces: hover/press, chip, tab, segmented.
  static const Duration durationFast = Duration(milliseconds: 140);

  /// Default: card, fade, sheet content.
  static const Duration durationBase = Duration(milliseconds: 220);

  /// Large / overlay: dialog, drawer, page.
  static const Duration durationSlow = Duration(milliseconds: 320);

  /// Reduced-motion primitive: near-zero (not exactly zero so completion
  /// callbacks still fire). When `MediaQuery.disableAnimations` is true the
  /// theme layer (WBS 2.6/2.7) swaps the scale durations to this value —
  /// kit contract KIT-04-05 / KIT-38-06.
  static const Duration durationNone = Duration(microseconds: 10);

  /// Feedback reveal: correct-match tile flash before it clears.
  static const Duration durationFlash = Duration(milliseconds: 300);

  /// Ambient loop period: skeleton shimmer.
  static const Duration durationPulse = Duration(milliseconds: 1300);

  /// Most in-place transitions.
  static const Cubic easeStandard = Cubic(0.2, 0, 0, 1);

  /// Enter: element settling in.
  static const Cubic easeDecelerate = Cubic(0, 0, 0, 1);

  /// Exit: element leaving.
  static const Cubic easeAccelerate = Cubic(0.3, 0, 1, 1);

  /// Duration tokens in milliseconds keyed by frozen CSS name (parity).
  static const Map<String, double> durationMsByToken = <String, double>{
    '--memox-duration-instant': 80,
    '--memox-duration-fast': 140,
    '--memox-duration-base': 220,
    '--memox-duration-slow': 320,
    '--memox-duration-none': 0.01,
    '--memox-duration-flash': 300,
    '--memox-duration-pulse': 1300,
  };

  /// Easing tokens keyed by frozen CSS name.
  static const Map<String, Cubic> easingByToken = <String, Cubic>{
    '--memox-ease-standard': easeStandard,
    '--memox-ease-decelerate': easeDecelerate,
    '--memox-ease-accelerate': easeAccelerate,
  };
}
