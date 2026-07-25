import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/today/screens/today_screen.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

/// WBS 5.7.2 — the Today entry renders one primary action per projection state,
/// plus loading (no fake zeros) and load-error (`load-today-dashboard.md`).
void main() {
  Widget wrap(Override override) => ProviderScope(
    overrides: [override],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TodayScreen(),
    ),
  );

  Override data(TodayProjection projection) =>
      todayProjectionProvider.overrideWith((ref) => Future.value(projection));

  testWidgets('a paused session offers Resume', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.continueSession,
            dueCount: 12,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Study session paused'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Resume session'), findsOneWidget);
  });

  testWidgets('due cards offer Start review with the count', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.startReview,
            dueCount: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 cards due'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Start review'), findsOneWidget);
  });

  testWidgets('an empty library offers Create a deck', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.createLibrary,
            dueCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start your first deck'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Create a deck'), findsOneWidget);
  });

  testWidgets('caught up shows the all-caught-up message', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.caughtUp,
            dueCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  testWidgets('loading shows no fake zeros', (tester) async {
    final never = Completer<TodayProjection>();
    await tester.pumpWidget(
      wrap(todayProjectionProvider.overrideWith((ref) => never.future)),
    );
    await tester.pump();
    // No "0 cards due" or a result while finalizing.
    expect(find.textContaining('0 cards due'), findsNothing);
    expect(find.text('Start review'), findsNothing);
  });

  testWidgets('a load error offers Retry', (tester) async {
    await tester.pumpWidget(
      wrap(
        todayProjectionProvider.overrideWith(
          (ref) => Future<TodayProjection>.error('boom'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today couldn’t load'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Retry'), findsOneWidget);
  });
}
