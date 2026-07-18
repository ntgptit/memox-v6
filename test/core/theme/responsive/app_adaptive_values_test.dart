import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/responsive/app_breakpoints.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';

void main() {
  test('gutter maps to the kit token per class', () {
    expect(
      AdaptiveSpacing.of(ScreenClass.compactMobile).gutter,
      AppSpacing.gutter,
    );
    expect(AdaptiveSpacing.of(ScreenClass.compact).gutter, AppSpacing.gutter);
    expect(
      AdaptiveSpacing.of(ScreenClass.medium).gutter,
      AppSpacing.gutterMedium,
    );
    expect(
      AdaptiveSpacing.of(ScreenClass.expanded).gutter,
      AppSpacing.gutterExpanded,
    );
    expect(
      AdaptiveSpacing.of(ScreenClass.large).gutter,
      AppSpacing.gutterExpanded,
    );
  });

  test('reduced density applies only to the compact-mobile class', () {
    for (final screenClass in ScreenClass.values) {
      expect(
        AdaptiveSpacing.of(screenClass).reducedDensity,
        screenClass == ScreenClass.compactMobile,
        reason: screenClass.name,
      );
    }
  });

  test('content caps come straight from the kit width tokens', () {
    final layout = AdaptiveLayout.of(ScreenClass.large);

    expect(
      layout.maxWidthFor(ContentSurface.reading),
      AppSpacing.contentWidthReading,
    );
    expect(
      layout.maxWidthFor(ContentSurface.study),
      AppSpacing.contentWidthStudy,
    );
    expect(
      layout.maxWidthFor(ContentSurface.list),
      AppSpacing.contentWidthList,
    );
    expect(
      layout.maxWidthFor(ContentSurface.dashboard),
      AppSpacing.contentWidthDashboard,
    );
  });

  test('navigation container follows the width contract', () {
    expect(
      AdaptiveLayout.of(ScreenClass.compactMobile).usesBottomNavigation,
      isTrue,
    );
    expect(AdaptiveLayout.of(ScreenClass.compact).usesBottomNavigation, isTrue);
    expect(AdaptiveLayout.of(ScreenClass.medium).usesNavigationRail, isTrue);
    expect(AdaptiveLayout.of(ScreenClass.expanded).usesNavigationRail, isTrue);
    expect(AdaptiveLayout.of(ScreenClass.large).usesNavigationRail, isTrue);
    expect(AdaptiveLayout.of(ScreenClass.large).usesBottomNavigation, isFalse);
  });

  testWidgets('context accessors adapt across window widths', (tester) async {
    Future<(AdaptiveSpacing, AdaptiveLayout)> resolveAt(double width) async {
      late AdaptiveSpacing spacing;
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Builder(
            builder: (context) {
              spacing = context.spacing;
              layout = context.layout;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return (spacing, layout);
    }

    final (phoneSpacing, phoneLayout) = await resolveAt(390);
    expect(phoneSpacing.gutter, AppSpacing.gutter);
    expect(phoneSpacing.reducedDensity, isTrue);
    expect(
      phoneSpacing.screenPadding,
      const EdgeInsets.symmetric(horizontal: 16),
    );
    expect(phoneLayout.usesBottomNavigation, isTrue);

    final (desktopSpacing, desktopLayout) = await resolveAt(1440);
    expect(desktopSpacing.gutter, AppSpacing.gutterExpanded);
    expect(desktopSpacing.reducedDensity, isFalse);
    expect(desktopLayout.usesNavigationRail, isTrue);
  });
}
