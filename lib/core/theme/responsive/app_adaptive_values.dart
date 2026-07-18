import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/responsive/app_breakpoints.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';

/// Adaptive family values — child B of WBS 2.8.
///
/// Every value is grounded in a kit token; the class→value mapping follows
/// the WBS §5.3 window contract. Features consume `context.spacing` and
/// `context.layout`; they never branch on raw widths themselves.

/// Spacing values that adapt with the window class.
@immutable
final class AdaptiveSpacing {
  const AdaptiveSpacing._({required this.gutter, required this.reducedDensity});

  factory AdaptiveSpacing.of(ScreenClass screenClass) => switch (screenClass) {
    ScreenClass.compactMobile => const AdaptiveSpacing._(
      gutter: AppSpacing.gutter,
      reducedDensity: true,
    ),
    ScreenClass.compact => const AdaptiveSpacing._(
      gutter: AppSpacing.gutter,
      reducedDensity: false,
    ),
    ScreenClass.medium => const AdaptiveSpacing._(
      gutter: AppSpacing.gutterMedium,
      reducedDensity: false,
    ),
    ScreenClass.expanded || ScreenClass.large => const AdaptiveSpacing._(
      gutter: AppSpacing.gutterExpanded,
      reducedDensity: false,
    ),
  };

  /// Screen edge padding for the current class
  /// (`gutter` / `gutter-medium` / `gutter-expanded`).
  final double gutter;

  /// Compact-mobile density contract (WBS §5.3): consumers may tighten
  /// intra-surface gaps by one 4px step, but never reduce touch targets
  /// below `AppSpacing.touchMin`.
  final bool reducedDensity;

  /// Symmetric horizontal screen-edge insets.
  EdgeInsets get screenPadding => EdgeInsets.symmetric(horizontal: gutter);
}

/// Content surfaces with kit-defined maximum widths.
enum ContentSurface { reading, study, list, dashboard }

/// Layout values that adapt with the window class.
@immutable
final class AdaptiveLayout {
  const AdaptiveLayout._(this.screenClass);

  factory AdaptiveLayout.of(ScreenClass screenClass) =>
      AdaptiveLayout._(screenClass);

  final ScreenClass screenClass;

  /// Kit content-width cap for [surface]; layouts center content and never
  /// stretch a phone surface across a large window.
  double maxWidthFor(ContentSurface surface) => switch (surface) {
    ContentSurface.reading => AppSpacing.contentWidthReading,
    ContentSurface.study => AppSpacing.contentWidthStudy,
    ContentSurface.list => AppSpacing.contentWidthList,
    ContentSurface.dashboard => AppSpacing.contentWidthDashboard,
  };

  /// Primary navigation container per WBS §5.3: bottom nav on compact
  /// classes, navigation rail from medium up (the large-class sidebar
  /// variant is a rail presentation owned by WBS 3.6).
  bool get usesBottomNavigation => screenClass.isCompactAny;

  bool get usesNavigationRail => screenClass.isMediumOrWider;

  /// Pane composition per WBS §5.3 (child C): single pane on compact
  /// classes, an optional compact two-region layout on medium, optional
  /// list/detail from expanded up.
  PaneRule get paneRule => switch (screenClass) {
    ScreenClass.compactMobile || ScreenClass.compact => PaneRule.single,
    ScreenClass.medium => PaneRule.optionalTwoRegion,
    ScreenClass.expanded || ScreenClass.large => PaneRule.optionalListDetail,
  };

  /// Large class never stretches phone surfaces: content is centered and
  /// capped by [maxWidthFor].
  bool get centersCappedContent => screenClass == ScreenClass.large;
}

/// Pane composition options (WBS §5.3).
enum PaneRule { single, optionalTwoRegion, optionalListDetail }

/// Component values that adapt with the window (WBS 2.8 child C).
///
/// Each value is grounded in a kit component contract; new entries are
/// added only when their owning `Mx*` spec lands (3.x).
@immutable
final class AdaptiveComponent {
  const AdaptiveComponent._();

  // Current values are class-independent caps; the class-taking factory
  // keeps the call-site contract stable for when class-dependent values
  // arrive with their owning Mx specs.
  factory AdaptiveComponent.of(ScreenClass _) => const AdaptiveComponent._();

  /// Dialog panel cap on wide screens (kit `.dialog` max-width =
  /// `--memox-size-5xl`); panels stay full-width below it.
  double get dialogMaxWidth => AppSizes.size5xl;
}

/// Feature-facing adaptive accessors (WBS 2.8 children B–C).
extension AppAdaptiveContext on BuildContext {
  AdaptiveSpacing get spacing => AdaptiveSpacing.of(screenClass);

  AdaptiveLayout get layout => AdaptiveLayout.of(screenClass);

  AdaptiveComponent get component => AdaptiveComponent.of(screenClass);
}
