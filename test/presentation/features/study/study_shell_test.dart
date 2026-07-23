import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/widgets/study_shell.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';

/// WBS 5.6.4 — the shared study shell composes the app bar, progress + counter,
/// body and optional bottom bar (kit `review-mode`).
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('renders title, progress counter, body and bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        StudyShell(
          title: 'Review',
          progress: 0.35,
          progressCounter: '7/20',
          progressSemanticLabel: '7 of 20',
          onBack: () {},
          backLabel: 'Back',
          body: const Text('BODY', key: Key('body')),
          bottomBar: const Text('BOTTOM', key: Key('bottom')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('7/20'), findsOneWidget);
    expect(find.byType(MxProgress), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
    expect(find.byKey(const Key('bottom')), findsOneWidget);
  });

  testWidgets('omits the bottom bar when none is given', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudyShell(
          title: 'Guess',
          progress: 1,
          progressCounter: '5/5',
          progressSemanticLabel: '5 of 5',
          onBack: () {},
          backLabel: 'Back',
          body: const Text('BODY', key: Key('body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bottom')), findsNothing);
    expect(find.text('5/5'), findsOneWidget);
  });
}
