import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_list.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('MxList', () {
    testWidgets('spaces items with the standard space-3 gap', (tester) async {
      await tester.pumpWidget(
        _host(
          const MxList(
            children: [MxText('one'), MxText('two'), MxText('three')],
          ),
        ),
      );

      final gaps = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((box) => box.height == AppSpacing.space3);
      expect(gaps, hasLength(2));
    });

    testWidgets('accepts a denser token gap', (tester) async {
      await tester.pumpWidget(
        _host(
          const MxList(
            gap: AppSpacing.space2,
            children: [MxText('a'), MxText('b')],
          ),
        ),
      );

      final gaps = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((box) => box.height == AppSpacing.space2);
      expect(gaps, hasLength(1));
    });
  });

  group('MxIconTile', () {
    Container tileOf(WidgetTester tester) =>
        tester.widget<Container>(find.byType(Container).first);

    testWidgets('default tile is a 48 square on the primary tint', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MxIconTile(icon: Symbols.style)));

      final size = tester.getSize(find.byType(MxIconTile));
      expect(size.width, AppComponentDimensions.iconTileMd);
      expect(size.height, AppComponentDimensions.iconTileMd);
      final decoration = tileOf(tester).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.light.primarySoft);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, AppIconSizes.lg);
      expect(icon.color, AppColors.light.onPrimarySoft);
    });

    testWidgets('accent tone pairs the soft tint with the bright accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MxIconTile(icon: Symbols.style, tone: MxIconTileTone.accent),
        ),
      );

      final decoration = tileOf(tester).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.light.accentSoft);
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.light.accent,
      );
    });

    testWidgets('semantic tones use their soft/on-soft pairs', (tester) async {
      for (final (tone, bg, fg) in [
        (
          MxIconTileTone.success,
          AppColors.light.successSoft,
          AppColors.light.onSuccessSoft,
        ),
        (
          MxIconTileTone.warning,
          AppColors.light.warningSoft,
          AppColors.light.onWarningSoft,
        ),
        (
          MxIconTileTone.error,
          AppColors.light.errorSoft,
          AppColors.light.onErrorSoft,
        ),
      ]) {
        await tester.pumpWidget(
          _host(MxIconTile(icon: Symbols.style, tone: tone)),
        );
        final decoration = tileOf(tester).decoration! as BoxDecoration;
        expect(decoration.color, bg, reason: tone.name);
        expect(
          tester.widget<Icon>(find.byType(Icon)).color,
          fg,
          reason: tone.name,
        );
      }
    });

    testWidgets('solid fills with the strong primary pair', (tester) async {
      await tester.pumpWidget(
        _host(const MxIconTile(icon: Symbols.style, solid: true)),
      );

      final decoration = tileOf(tester).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.light.primary);
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.light.onPrimary,
      );
    });

    testWidgets('large tile raises size, radius and glyph', (tester) async {
      await tester.pumpWidget(
        _host(const MxIconTile(icon: Symbols.style, large: true)),
      );

      final size = tester.getSize(find.byType(MxIconTile));
      expect(size.width, AppComponentDimensions.iconTileLg);
      expect(tester.widget<Icon>(find.byType(Icon)).size, AppIconSizes.xl);
    });

    testWidgets('tile is decorative unless a label is provided', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MxIconTile(icon: Symbols.style)));
      expect(find.byType(ExcludeSemantics), findsWidgets);

      await tester.pumpWidget(
        _host(
          const MxIconTile(icon: Symbols.style, semanticLabel: 'Deck icon'),
        ),
      );
      expect(find.bySemanticsLabel('Deck icon'), findsOneWidget);
    });
  });
}
