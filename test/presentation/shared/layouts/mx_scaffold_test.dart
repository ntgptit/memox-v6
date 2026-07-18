import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_content_shell.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

Widget _app(Widget screen) =>
    MaterialApp(theme: AppTheme.light(), home: screen);

void main() {
  testWidgets('slots render and the body scrolls under a short viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        MxScaffold(
          appBar: AppBar(title: const Text('Today')),
          bottomNav: const SizedBox(height: 56, child: MxText('nav')),
          fab: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [for (var i = 0; i < 30; i++) MxText('row $i')],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('nav'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('gutter follows the screen class through MxContentShell', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(390, 780);
    await tester.pumpWidget(_app(const MxScaffold(body: MxText('content'))));
    Padding gutterPadding() => tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(MxContentShell),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(
      gutterPadding().padding,
      const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    );

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(
      gutterPadding().padding,
      const EdgeInsets.symmetric(horizontal: AppSpacing.gutterExpanded),
    );
  });

  testWidgets('flush drops the gutter for full-bleed bodies', (tester) async {
    await tester.pumpWidget(
      _app(const MxScaffold(flush: true, body: MxText('full bleed'))),
    );

    expect(
      find.descendant(
        of: find.byType(MxContentShell),
        matching: find.byType(Padding),
      ),
      findsNothing,
    );
  });

  testWidgets('surface cap centers the body on wide windows', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const MxScaffold(
          surface: ContentSurface.study,
          body: SizedBox(
            width: double.infinity,
            child: MxText('study content'),
          ),
        ),
      ),
    );

    final width = tester
        .getSize(
          find
              .ancestor(
                of: find.text('study content'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .width;
    expect(width, lessThanOrEqualTo(AppSpacing.contentWidthStudy));
  });

  testWidgets('without bottom nav the scaffold has no nav slot', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const MxScaffold(body: MxText('body'))));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNull);
  });
}
