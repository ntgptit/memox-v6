import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_constrained_scaffolds.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

Widget _app(Widget screen) =>
    MaterialApp(theme: AppTheme.light(), home: screen);

void main() {
  testWidgets('list scaffold lazily builds rows with space-3 separators', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 780);
    addTearDown(tester.view.reset);

    final built = <int>[];
    await tester.pumpWidget(
      _app(
        MxListScaffold(
          itemCount: 500,
          itemBuilder: (context, index) {
            built.add(index);
            return SizedBox(height: 56, child: MxText('row $index'));
          },
        ),
      ),
    );

    expect(find.text('row 0'), findsOneWidget);
    // Lazy: nowhere near 500 rows built for a phone viewport.
    expect(built.length, lessThan(50));

    final separators = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((box) => box.height == AppSpacing.space3);
    expect(separators, isNotEmpty);

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect((listView.padding! as EdgeInsets).left, AppSpacing.gutter);
  });

  testWidgets('list scaffold caps and centers on large windows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        MxListScaffold(
          itemCount: 3,
          itemBuilder: (context, index) => MxText('row $index'),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(ListView)).width,
      lessThanOrEqualTo(AppSpacing.contentWidthList),
    );
  });

  testWidgets('list scaffold renders the empty state at zero items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MxListScaffold(
          itemCount: 0,
          itemBuilder: (context, index) => const SizedBox.shrink(),
          emptyState: const MxText('No decks yet'),
        ),
      ),
    );

    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('form scaffold constrains fields to the reading cap', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const MxFormScaffold(
          body: SizedBox(width: double.infinity, child: MxText('field')),
        ),
      ),
    );

    final width = tester
        .getSize(
          find
              .ancestor(
                of: find.text('field'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .width;
    expect(width, lessThanOrEqualTo(AppSpacing.contentWidthReading));
  });

  testWidgets('study scaffold constrains stages to the study cap', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const MxStudyScaffold(
          scrollable: false,
          body: SizedBox(width: double.infinity, child: MxText('prompt')),
        ),
      ),
    );

    final width = tester
        .getSize(
          find
              .ancestor(
                of: find.text('prompt'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .width;
    expect(width, lessThanOrEqualTo(AppSpacing.contentWidthStudy));
  });
}
