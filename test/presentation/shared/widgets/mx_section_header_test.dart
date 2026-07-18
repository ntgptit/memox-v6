import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_divider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_header.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('MxSectionHeader', () {
    testWidgets('renders title, caption and a working trailing action', (
      tester,
    ) async {
      var actions = 0;
      await tester.pumpWidget(
        _host(
          MxSectionHeader(
            title: 'Your decks',
            caption: '6 active',
            actionLabel: 'See all',
            onAction: () => actions++,
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Your decks'));
      expect(title.style?.fontSize, AppTypography.fontSizeMd);
      expect(title.style?.fontWeight, AppTypography.fontWeightBold);
      expect(find.text('6 active'), findsOneWidget);

      final action = tester.widget<Text>(find.text('See all'));
      expect(action.style?.color, AppColors.light.accent);
      await tester.tap(find.byType(MxTappable));
      expect(actions, 1);
    });

    testWidgets('renders without action when handler or label is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MxSectionHeader(title: 'Your decks')),
      );

      expect(find.byType(MxTappable), findsNothing);
    });

    testWidgets('long title ellipsizes instead of overflowing', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 780);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          MxSectionHeader(
            title: 'A very long localized section title ' * 3,
            actionLabel: 'See all',
            onAction: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('See all'), findsOneWidget);
    });
  });

  testWidgets('MxDivider uses the theme hairline', (tester) async {
    await tester.pumpWidget(_host(const MxDivider()));

    final context = tester.element(find.byType(Divider));
    expect(DividerTheme.of(context).color, AppColors.light.divider);
  });

  group('tap-behavior matrix', () {
    testWidgets('interactive surfaces expose button semantics; static never', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MxButton(onPressed: () {}, label: 'Act'),
              MxCard(
                onTap: () {},
                semanticLabel: 'Open card',
                child: const MxText('interactive'),
              ),
              MxSectionHeader(
                title: 'Group',
                actionLabel: 'See all',
                onAction: () {},
              ),
              const MxCard(child: MxText('static card')),
              const MxIconTile(icon: Symbols.style),
              const MxDivider(),
            ],
          ),
        ),
      );

      bool isButton(SemanticsNode node) =>
          node.getSemanticsData().flagsCollection.isButton;

      expect(
        isButton(tester.getSemantics(find.bySemanticsLabel('Act'))),
        isTrue,
      );
      expect(
        isButton(
          tester.getSemantics(find.bySemanticsLabel(RegExp('Open card'))),
        ),
        isTrue,
      );
      expect(
        isButton(tester.getSemantics(find.bySemanticsLabel('See all'))),
        isTrue,
      );
      // Static surfaces carry no tap semantics at all.
      expect(find.bySemanticsLabel('static card'), findsOneWidget);
      expect(isButton(tester.getSemantics(find.text('static card'))), isFalse);

      semantics.dispose();
    });
  });
}
