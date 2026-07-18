// Component dimension tokens (WBS 2.4) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/component.css —
// `--memox-comp-<component>-<prop>`, theme-independent.
// Parity gate: test/core/theme/dimension_css_parity_test.dart.

/// Fixed intrinsic sizes of individual controls.
abstract final class AppComponentDimensions {
  // Chip.
  static const double chipHeight = 34;

  // Switch (M3 spec 52x32; thumb grows 22 -> 24 when on).
  static const double switchWidth = 52;
  static const double switchHeight = 32;
  static const double switchThumb = 22;
  static const double switchThumbOn = 24;
  static const double switchThumbInset = 4;
  static const double switchThumbInsetOn = 2;
  static const double switchThumbTravel = 20;

  // Badge.
  static const double badgeHeight = 20;
  static const double badgeMinWidth = 20;
  static const double badgePadX = 6;
  static const double badgeGap = 4;
  static const double badgeDot = 10;

  // Avatar.
  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 64;

  // Icon tile.
  static const double iconTileMd = 48;
  static const double iconTileLg = 60;

  // Icon button (small visual; hit area extends to touch-min).
  static const double iconBtnSm = 36;

  // Search dock.
  static const double searchDockHeight = 52;

  // Bottom-nav internals.
  static const double navPillWidth = 56;
  static const double navPillHeight = 30;
  static const double navItemGap = 3;
  static const double navSafePad = 4;

  // Segmented control.
  static const double segmentedSegHeight = 40;

  /// Every component token keyed by its frozen CSS name.
  static const Map<String, double> byToken = <String, double>{
    '--memox-comp-chip-height': chipHeight,
    '--memox-comp-switch-width': switchWidth,
    '--memox-comp-switch-height': switchHeight,
    '--memox-comp-switch-thumb': switchThumb,
    '--memox-comp-switch-thumb-on': switchThumbOn,
    '--memox-comp-switch-thumb-inset': switchThumbInset,
    '--memox-comp-switch-thumb-inset-on': switchThumbInsetOn,
    '--memox-comp-switch-thumb-travel': switchThumbTravel,
    '--memox-comp-badge-height': badgeHeight,
    '--memox-comp-badge-min-width': badgeMinWidth,
    '--memox-comp-badge-pad-x': badgePadX,
    '--memox-comp-badge-gap': badgeGap,
    '--memox-comp-badge-dot': badgeDot,
    '--memox-comp-avatar-sm': avatarSm,
    '--memox-comp-avatar-md': avatarMd,
    '--memox-comp-avatar-lg': avatarLg,
    '--memox-comp-icon-tile-md': iconTileMd,
    '--memox-comp-icon-tile-lg': iconTileLg,
    '--memox-comp-icon-btn-sm': iconBtnSm,
    '--memox-comp-search-dock-height': searchDockHeight,
    '--memox-comp-nav-pill-width': navPillWidth,
    '--memox-comp-nav-pill-height': navPillHeight,
    '--memox-comp-nav-item-gap': navItemGap,
    '--memox-comp-nav-safe-pad': navSafePad,
    '--memox-comp-segmented-seg-height': segmentedSegHeight,
  };
}
