import 'package:flutter/widgets.dart';

/// Responsive foundation — child A of WBS 2.8.
///
/// Layout branches by available window width only (never device label or
/// orientation), per the WBS §5.3 contract and Flutter adaptive guidance.
/// All exact boundary values live here; features consume the class through
/// `context.screenClass` / `context.screenInfo`.
abstract final class AppBreakpoints {
  /// Below this width the compact class additionally reduces spacing
  /// density (without reducing touch targets).
  static const double compactMobileMax = 430;

  /// Compact (bottom nav, single pane) upper bound, exclusive.
  static const double compactMax = 600;

  /// Medium (rail or compact two-region) upper bound, exclusive.
  static const double mediumMax = 840;

  /// Expanded (rail, constrained content) upper bound, exclusive.
  static const double expandedMax = 1200;
}

/// Window width class (WBS §5.3).
enum ScreenClass {
  /// `< 430` — bottom nav, single pane, reduced spacing density.
  compactMobile,

  /// `< 600` — bottom nav, single pane.
  compact,

  /// `600–839` — rail or compact two-region layout when useful.
  medium,

  /// `840–1199` — navigation rail, constrained content, optional
  /// list/detail.
  expanded,

  /// `≥ 1200` — rail/sidebar, centered max-width content, no stretched
  /// phone surfaces.
  large;

  static ScreenClass fromWidth(double width) {
    if (width < AppBreakpoints.compactMobileMax) {
      return ScreenClass.compactMobile;
    }
    if (width < AppBreakpoints.compactMax) return ScreenClass.compact;
    if (width < AppBreakpoints.mediumMax) return ScreenClass.medium;
    if (width < AppBreakpoints.expandedMax) return ScreenClass.expanded;
    return ScreenClass.large;
  }

  /// Single-pane phone-style layouts (bottom nav).
  bool get isCompactAny =>
      this == ScreenClass.compactMobile || this == ScreenClass.compact;

  /// Rail/sidebar layouts (medium and wider).
  bool get isMediumOrWider => !isCompactAny;
}

/// Immutable snapshot of the window the layout is responding to.
@immutable
final class ScreenInfo {
  const ScreenInfo({required this.width, required this.screenClass});

  factory ScreenInfo.fromWidth(double width) =>
      ScreenInfo(width: width, screenClass: ScreenClass.fromWidth(width));

  final double width;
  final ScreenClass screenClass;

  @override
  bool operator ==(Object other) =>
      other is ScreenInfo &&
      other.width == width &&
      other.screenClass == screenClass;

  @override
  int get hashCode => Object.hash(width, screenClass);
}

/// Feature-facing responsive accessors (WBS 2.8). Uses `MediaQuery.sizeOf`
/// so consumers rebuild only when the size changes.
extension AppResponsiveContext on BuildContext {
  ScreenClass get screenClass =>
      ScreenClass.fromWidth(MediaQuery.sizeOf(this).width);

  ScreenInfo get screenInfo =>
      ScreenInfo.fromWidth(MediaQuery.sizeOf(this).width);
}
