import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_elevations.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_bottom_nav.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_fab.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_search_dock.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

// MxTappable's AnimatedContainer builds an internal Container carrying only
// the focus-ring border; the component surface is the one with a color.
Container _surfaceIn(WidgetTester tester, Type root) => tester
    .widgetList<Container>(
      find.descendant(of: find.byType(root), matching: find.byType(Container)),
    )
    .firstWhere((c) => (c.decoration as BoxDecoration?)?.color != null);

void main() {
  group('MxIconButton', () {
    testWidgets('default is a 48 transparent circle that fires', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MxIconButton(
            icon: Symbols.search,
            onPressed: () => taps++,
            semanticLabel: 'Search',
          ),
        ),
      );

      final size = tester.getSize(find.byType(MxIconButton));
      expect(size.width, greaterThanOrEqualTo(AppSpacing.touchMin));
      await tester.tap(find.byType(MxIconButton));
      expect(taps, 1);
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
    });

    testWidgets('toolbar preset is small but keeps the 48 target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MxIconButton.toolbar(
            icon: Symbols.arrow_back,
            onPressed: () {},
            semanticLabel: 'Back',
          ),
        ),
      );

      final visual = _surfaceIn(tester, MxIconButton);
      expect(visual.constraints?.minWidth, AppComponentDimensions.iconBtnSm);
      expect(
        tester.getSize(find.byType(MxIconButton)).width,
        greaterThanOrEqualTo(AppSpacing.touchMin),
      );
    });

    testWidgets('primary variant uses the tonal pair', (tester) async {
      await tester.pumpWidget(
        _host(
          MxIconButton(
            icon: Symbols.bolt,
            onPressed: () {},
            semanticLabel: 'Streak',
            variant: MxIconButtonVariant.primary,
          ),
        ),
      );

      final decoration =
          _surfaceIn(tester, MxIconButton).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.light.primarySoft);
    });
  });

  group('MxFab', () {
    testWidgets('extended FAB fills brand with label and shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(MxFab(icon: Symbols.add, onPressed: () {}, label: 'New deck')),
      );

      expect(find.text('New deck'), findsOneWidget);
      final decoration = _surfaceIn(tester, MxFab).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.light.primary);
      expect(decoration.boxShadow, AppElevations.light.shadowFab);
      expect(
        _surfaceIn(tester, MxFab).constraints?.minHeight ?? AppSpacing.fabSize,
        AppSpacing.fabSize,
      );
    });

    testWidgets('round FAB is a 56 circle with required semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MxFab(
            icon: Symbols.shuffle,
            onPressed: () {},
            semanticLabel: 'Shuffle',
          ),
        ),
      );

      final surface = _surfaceIn(tester, MxFab);
      expect(
        (surface.decoration! as BoxDecoration).color,
        AppColors.light.primary,
      );
      expect(find.bySemanticsLabel('Shuffle'), findsOneWidget);
    });
  });

  group('MxBottomNav', () {
    testWidgets('active item gets the tonal pill and reports changes', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _host(
          MxBottomNav(
            value: 'home',
            onChanged: (id) => selected = id,
            items: const [
              MxBottomNavItem(id: 'home', label: 'Today', icon: Symbols.today),
              MxBottomNavItem(
                id: 'library',
                label: 'Library',
                icon: Symbols.style,
              ),
            ],
          ),
        ),
      );

      // Pills are the AnimatedContainers with a color (tappable focus rings
      // carry only a border).
      final pill = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .whereType<Color>()
          .toList();
      expect(pill.first, AppColors.light.primarySoft);
      expect(pill.last.a, 0);

      await tester.tap(find.text('Library'));
      expect(selected, 'library');
    });

    testWidgets('five items fit a 320px frame', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 780);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          MxBottomNav(
            value: 'a',
            onChanged: (_) {},
            items: const [
              MxBottomNavItem(id: 'a', label: 'Today', icon: Symbols.today),
              MxBottomNavItem(id: 'b', label: 'Library', icon: Symbols.style),
              MxBottomNavItem(id: 'c', label: 'Search', icon: Symbols.search),
              MxBottomNavItem(id: 'd', label: 'Stats', icon: Symbols.bar_chart),
              MxBottomNavItem(
                id: 'e',
                label: 'Settings',
                icon: Symbols.settings,
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MxBottomNav)).height,
        AppSpacing.bottomNavHeight,
      );
    });
  });

  group('MxContextualAppBar', () {
    testWidgets('root variant shows the title at 56', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            appBar: MxContextualAppBar(title: 'Library'),
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('Library'), findsOneWidget);
      expect(
        const MxContextualAppBar(title: 'Library').preferredSize.height,
        AppSpacing.appbarHeight,
      );
    });

    testWidgets('child variant leads with a working Back action', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: MxContextualAppBar(
              title: 'Deck',
              onBack: () => backs++,
              backLabel: 'Back',
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(MxIconButton));
      expect(backs, 1);
    });

    testWidgets('contextual root adds the caption line and taller bar', (
      tester,
    ) async {
      const bar = MxContextualAppBar(
        title: 'Today',
        contextLine: 'Saturday · 27 Jun',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(appBar: bar, body: SizedBox.shrink()),
        ),
      );

      expect(find.text('Saturday · 27 Jun'), findsOneWidget);
      expect(bar.preferredSize.height, AppSpacing.appbarLgHeight);
    });
  });

  group('MxSearchDock', () {
    testWidgets('elevated dock carries the shadow and trailing control', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MxSearchDock(
            placeholder: 'Search decks & cards',
            clearLabel: 'Clear',
            trailing: MxIconButton.toolbar(
              icon: Symbols.tune,
              onPressed: () {},
              semanticLabel: 'Filters',
            ),
          ),
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      expect(decoration.boxShadow, AppElevations.light.shadowSm);
      expect(find.bySemanticsLabel('Filters'), findsOneWidget);
    });

    testWidgets('flat dock drops the shadow', (tester) async {
      await tester.pumpWidget(
        _host(const MxSearchDock(clearLabel: 'Clear', flat: true)),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });
  });
}
