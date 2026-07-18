import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_search_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders the pill ground at the dock height', (tester) async {
    await tester.pumpWidget(
      _host(const MxSearchField(placeholder: 'Search', clearLabel: 'Clear')),
    );

    final container = tester.widget<Container>(
      find.ancestor(of: find.byType(Row), matching: find.byType(Container)),
    );
    expect(
      (container.decoration! as BoxDecoration).color,
      AppColors.light.surface,
    );
    expect(
      tester.getSize(find.byType(MxSearchField)).height,
      AppComponentDimensions.searchDockHeight,
    );
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('flat variant uses the muted ground', (tester) async {
    await tester.pumpWidget(
      _host(const MxSearchField(clearLabel: 'Clear', flat: true)),
    );

    final container = tester.widget<Container>(
      find.ancestor(of: find.byType(Row), matching: find.byType(Container)),
    );
    expect(
      (container.decoration! as BoxDecoration).color,
      AppColors.light.surfaceMuted,
    );
  });

  testWidgets('clear affordance appears with content and resets it', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _host(MxSearchField(clearLabel: 'Clear search', onChanged: changes.add)),
    );

    expect(find.byType(MxTappable), findsNothing);

    await tester.enterText(find.byType(TextField), 'kanji');
    await tester.pump();
    expect(find.byType(MxTappable), findsOneWidget);

    await tester.tap(find.byType(MxTappable));
    await tester.pump();
    expect(find.byType(MxTappable), findsNothing);
    expect(changes.last, '');
    expect(find.text('kanji'), findsNothing);
  });

  testWidgets('focusing shows the branded ring on the pill', (tester) async {
    await tester.pumpWidget(_host(const MxSearchField(clearLabel: 'Clear')));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.ancestor(of: find.byType(Row), matching: find.byType(Container)),
    );
    final border = (container.decoration! as BoxDecoration).border!;
    expect(border.top.color, AppColors.light.focusRing);
  });
}
