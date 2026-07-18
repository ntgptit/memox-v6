// Spacing / layout-rhythm tokens (WBS 2.4) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/spacing.css (4px base).
// Parity gate: test/core/theme/dimension_css_parity_test.dart re-parses the
// CSS on every verifier run. Token NAMES are frozen (additive-only).

/// 4px-rhythm spacing scale plus layout metrics.
abstract final class AppSpacing {
  static const double space0 = 0;
  static const double space05 = 2;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 48;
  static const double space10 = 64;
  static const double space11 = 80;
  static const double space12 = 96;

  /// Compact screen edge padding.
  static const double gutter = 16;
  static const double gutterMedium = 24;
  static const double gutterExpanded = 32;

  static const double contentWidthReading = 640;
  static const double contentWidthStudy = 720;
  static const double contentWidthList = 1200;
  static const double contentWidthDashboard = 1280;

  /// Minimum top inset above app bars; the platform safe-area inset wins
  /// when larger (kit: `max(env(safe-area-inset-top, 0px), 24px)`).
  static const double safeAreaTopMin = 24;

  /// Minimum bottom inset below bottom-nav/sheets; the platform inset wins
  /// when larger (kit fallback = `--memox-comp-nav-safe-pad`).
  static const double safeAreaBottomMin = 4;

  /// Single compact app-bar height (minimal M3).
  static const double appbarHeight = 56;

  /// DEPRECATED in the kit (kept until v5; names are additive-only): the
  /// large/hero app bar was retired for the compact MxContextualAppBar.
  static const double appbarLgHeight = 112;

  /// M3 navigation bar height.
  static const double bottomNavHeight = 80;

  /// M3 standard FAB.
  static const double fabSize = 56;

  /// Minimum touch target.
  static const double touchMin = 48;

  // Layout-namespace aliases (same values as their element-named originals).
  static const double layoutAppbarHeight = appbarHeight;
  static const double layoutBottomNavHeight = bottomNavHeight;
  static const double layoutFabSize = fabSize;

  /// Every spacing token keyed by its frozen CSS name. Safe-area tokens map
  /// to their kit-rendered minimum inset values.
  static const Map<String, double> byToken = <String, double>{
    '--memox-space-0': space0,
    '--memox-space-05': space05,
    '--memox-space-1': space1,
    '--memox-space-2': space2,
    '--memox-space-3': space3,
    '--memox-space-4': space4,
    '--memox-space-5': space5,
    '--memox-space-6': space6,
    '--memox-space-7': space7,
    '--memox-space-8': space8,
    '--memox-space-9': space9,
    '--memox-space-10': space10,
    '--memox-space-11': space11,
    '--memox-space-12': space12,
    '--memox-gutter': gutter,
    '--memox-gutter-medium': gutterMedium,
    '--memox-gutter-expanded': gutterExpanded,
    '--memox-content-width-reading': contentWidthReading,
    '--memox-content-width-study': contentWidthStudy,
    '--memox-content-width-list': contentWidthList,
    '--memox-content-width-dashboard': contentWidthDashboard,
    '--memox-safe-area-top': safeAreaTopMin,
    '--memox-safe-area-bottom': safeAreaBottomMin,
    '--memox-appbar-height': appbarHeight,
    '--memox-appbar-lg-height': appbarLgHeight,
    '--memox-bottom-nav-height': bottomNavHeight,
    '--memox-fab-size': fabSize,
    '--memox-touch-min': touchMin,
    '--memox-layout-appbar-height': layoutAppbarHeight,
    '--memox-layout-bottom-nav-height': layoutBottomNavHeight,
    '--memox-layout-fab-size': layoutFabSize,
  };
}
