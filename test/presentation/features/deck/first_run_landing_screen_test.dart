import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/usecases/onboarding/dismiss_first_run_usecase.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.firstRunLanding,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('home-stub')),
        ),
        GoRoute(
          path: RoutePaths.firstRunLanguage,
          builder: (context, state) =>
              const Scaffold(body: Text('language-step-stub')),
        ),
        ...deckRoutes(),
      ],
    );
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets('renders the three CTAs with import pending its flow', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Build your learning library'), findsOneWidget);
    expect(find.text('Create your first deck'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    final importButton = tester.widget<MxButton>(
      find.widgetWithText(MxButton, 'Import existing cards'),
    );
    expect(importButton.onPressed, isNull);
  });

  testWidgets('the primary CTA opens step 1 (language setup)', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create your first deck'));
    await tester.pumpAndSettle();

    expect(find.text('language-step-stub'), findsOneWidget);
  });

  testWidgets('Not now persists the dismissal and lands on the dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('home-stub'), findsOneWidget);

    final flag = await database.preferenceDao
        .findPreference(DismissFirstRunUseCase.preferenceKey)
        .getSingle();
    expect(flag.valueJson, 'true');
  });
}
