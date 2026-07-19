import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_constrained_scaffolds.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Shell-family stress matrix (WBS 3.5 child C): RTL mirroring, safe-area
/// insets, short viewports and retained composition across resizes.

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int value = 0;

  @override
  Widget build(BuildContext context) {
    return MxText('count ${value++}');
  }
}

void main() {
  Widget app(Widget screen, {MediaQueryData? mediaQuery}) {
    Widget home = screen;
    if (mediaQuery != null) {
      home = MediaQuery(data: mediaQuery, child: home);
    }
    return MaterialApp(theme: AppTheme.light(), home: home);
  }

  testWidgets('the whole frame mirrors under RTL without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MxScaffold(
            appBar: AppBar(title: const Text('عنوان')),
            bottomNav: const SizedBox(height: 56, child: MxText('nav')),
            body: const Align(
              alignment: AlignmentDirectional.centerStart,
              child: MxText('محتوى'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Logical start resolves to the RIGHT edge under RTL.
    final content = tester.getTopRight(find.text('محتوى'));
    final frame = tester.getTopRight(find.byType(MxScaffold));
    expect(frame.dx - content.dx, lessThan(100), reason: 'starts at right');
  });

  testWidgets('safe-area insets reach body and nav without doubling', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 780);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(
        MxScaffold(
          bottomNav: const SizedBox(height: 56, child: MxText('nav')),
          body: const MxText('body'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // Body starts below the top inset.
    expect(tester.getTopLeft(find.text('body')).dy, greaterThanOrEqualTo(47));
    // Nav bottom sits above the bottom inset.
    expect(
      tester.getBottomLeft(find.text('nav')).dy,
      lessThanOrEqualTo(780 - 34),
    );
  });

  testWidgets('constrained shells survive a 320x480 viewport', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(
        MxFormScaffold(
          appBar: AppBar(title: const Text('Form')),
          body: Column(
            children: [for (var i = 0; i < 20; i++) MxText('field $i')],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      app(
        MxStudyScaffold(
          body: Column(
            children: [for (var i = 0; i < 20; i++) MxText('line $i')],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      app(
        MxListScaffold(
          itemCount: 100,
          itemBuilder: (context, index) => MxText('row $index'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('composition is retained across window resizes', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 780);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const MxScaffold(body: _Counter())));
    final initialState = tester.state<_CounterState>(find.byType(_Counter));

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 780);
    await tester.pumpAndSettle();

    // Same State object: the shell never remounts the body subtree while
    // the window class changes.
    expect(
      tester.state<_CounterState>(find.byType(_Counter)),
      same(initialState),
    );
  });
}
