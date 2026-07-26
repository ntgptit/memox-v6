import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_stat.dart';

/// WBS 3.x shared widget — the kit `Stat` chip.
void main() {
  Future<void> pump(WidgetTester tester, MxStatTone tone) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: MxStat(
          icon: Symbols.verified_rounded,
          tone: tone,
          value: '55%',
          label: 'library mastered',
        ),
      ),
    ),
  );

  testWidgets('shows the value over its label', (tester) async {
    await pump(tester, MxStatTone.success);

    expect(find.text('55%'), findsOneWidget);
    expect(find.text('library mastered'), findsOneWidget);

    final value = tester.getTopLeft(find.text('55%'));
    final label = tester.getTopLeft(find.text('library mastered'));
    expect(label.dy, greaterThan(value.dy));
    expect(label.dx, value.dx, reason: 'both start at the same left edge');
  });

  // The chip is `radius-control`, not the deck tile's `radius-tile` — the one
  // thing that would make it read as the wrong component.
  testWidgets('the chip uses the control radius', (tester) async {
    await pump(tester, MxStatTone.success);

    final container = tester.widget<Container>(
      find.ancestor(of: find.byType(Icon), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, AppBorderRadii.control);
  });

  // The glyph sits on the soft tint, so the accent tone takes the bright
  // accent rather than on-accent, which is meant for a solid fill.
  testWidgets('the accent tone tints the glyph, not inverts it', (
    tester,
  ) async {
    await pump(tester, MxStatTone.accent);

    final context = tester.element(find.byType(MxStat));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, context.colors.accent);
  });
}
