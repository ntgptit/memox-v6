import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';

/// The kit `Snackbar` — the surface that says an action landed.
///
/// Until this existed no flow in the app confirmed anything: dialogs closed
/// and success looked exactly like nothing having happened (`int-33`).
void main() {
  Widget host(void Function(BuildContext context) onTap) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => onTap(context),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );

  testWidgets('a success bar carries the tone glyph and its own ground', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        (context) => showMxSnackbar(context, message: 'Deck progress reset'),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.text('Deck progress reset'), findsOneWidget);
    expect(find.byIcon(Symbols.check_circle_rounded), findsOneWidget);

    // The bar draws the tonal container; the Material shell around it is
    // transparent, so the tokens are the only thing painting it.
    final bar = tester.widget<Container>(
      find.descendant(
        of: find.byType(MxSnackbar),
        matching: find.byType(Container),
      ),
    );
    final decoration = bar.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.light.snackbarSuccessBg);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).elevation, 0);
  });

  testWidgets('a neutral bar carries no glyph', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => showMxSnackbar(
          context,
          message: 'Saved',
          tone: MxSnackbarTone.neutral,
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Symbols.check_circle_rounded), findsNothing);
  });

  testWidgets('the action runs and takes the bar with it', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      host(
        (context) => showMxSnackbar(
          context,
          message: 'Deck created',
          action: MxSnackbarAction(label: 'Open', onPressed: () => opened++),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    // Settled, not pumped: the bar slides in, and tapping mid-animation
    // would be tapping where it is about to be.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(
      find.text('Deck created'),
      findsNothing,
      reason: 'a transient bar does not follow the learner to the destination',
    );
  });

  // `navigation-overlays.md`: a status message is not a focus layer, and a
  // second confirmation supersedes the first rather than queueing behind it.
  testWidgets('a second bar replaces the first', (tester) async {
    var shown = 0;
    await tester.pumpWidget(
      host((context) => showMxSnackbar(context, message: 'Message ${shown++}')),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Message 0'), findsNothing);
    expect(find.text('Message 1'), findsOneWidget);
  });
}
