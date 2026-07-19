import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('MxText', () {
    testWidgets('renders roles with the kit style and default color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MxText('Title', role: MxTextRole.title)),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, AppTypography.fontSizeXl);
      expect(text.style?.fontWeight, AppTypography.fontWeightBold);
      expect(text.style?.color, AppColors.light.text);
    });

    testWidgets('caption defaults to the secondary text color', (tester) async {
      await tester.pumpWidget(
        _host(const MxText('meta', role: MxTextRole.caption)),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, AppColors.light.textSecondary);
    });

    testWidgets('overline uppercases and applies caps tracking', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MxText('due today', role: MxTextRole.overline)),
      );

      expect(find.text('DUE TODAY'), findsOneWidget);
      final text = tester.widget<Text>(find.byType(Text));
      expect(
        text.style?.letterSpacing,
        AppTypography.letterSpacingFor(
          AppTypography.letterSpacingCapsEm,
          AppTypography.fontSizeXs,
        ),
      );
    });
  });

  group('MxIcon', () {
    testWidgets('renders a Symbols glyph at the token size', (tester) async {
      await tester.pumpWidget(_host(const MxIcon(icon: Symbols.check)));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, AppIconSizes.md);
      expect(icon.color, AppColors.light.text);
      expect(icon.icon, Symbols.check);
    });
  });

  group('MxTappable', () {
    testWidgets('fires onTap and exposes button semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MxTappable(
            onTap: () => taps++,
            semanticLabel: 'Open deck',
            child: const MxText('Open'),
          ),
        ),
      );

      await tester.tap(find.byType(MxTappable));
      expect(taps, 1);
      final node = tester.getSemantics(find.byType(MxTappable));
      expect(node.label, contains('Open deck'));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('enforces the 48px minimum touch target', (tester) async {
      await tester.pumpWidget(
        _host(
          MxTappable(
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final size = tester.getSize(find.byType(MxTappable));
      expect(size.width, greaterThanOrEqualTo(AppSpacing.touchMin));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.touchMin));
    });

    testWidgets('shows the focus ring when focused via keyboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(MxTappable(onTap: () {}, child: const MxText('Focus me'))),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final border = (container.foregroundDecoration! as BoxDecoration).border!;
      expect(border.top.color, AppColors.light.focusRing);
    });

    testWidgets('null onTap renders a disabled surface', (tester) async {
      await tester.pumpWidget(
        _host(
          const MxTappable(
            onTap: null,
            semanticLabel: 'Disabled row',
            child: MxText('Disabled'),
          ),
        ),
      );

      await tester.tap(find.byType(MxTappable));
      expect(tester.takeException(), isNull);
    });
  });

  group('MxGap', () {
    testWidgets('gaps match the spacing scale', (tester) async {
      await tester.pumpWidget(
        _host(const Column(children: [MxGap.s4(), MxGap.s7()])),
      );

      final sizes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .map((box) => box.height)
          .whereType<double>()
          .toList();
      expect(
        sizes,
        containsAll(<double>[AppSpacing.space4, AppSpacing.space7]),
      );
    });
  });
}
