import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/routes/study_routes.dart';

/// WBS 5.6.1 — the Practice mode picker (`study-deck.md` §4, §6; kit
/// `ModePicker.jsx`).
///
/// §6: "Mode Picker là selection surface và luôn có CTA `Start session`; chọn
/// một tile không tự start." The app had no such surface at all — the deck
/// row's bolt starts a session on one tap (`int-108`).
void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.preferenceDao.upsertPreference(
      'activeLanguagePairId',
      '"lp1"',
      1,
      0,
    );
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
    const seeded = <(String, String, String)>[
      ('c1', 'hello', 'xin chào'),
      ('c2', 'goodbye', 'tạm biệt'),
      ('c3', 'please', 'làm ơn'),
      ('c4', 'thanks', 'cảm ơn'),
      ('c5', 'sorry', 'xin lỗi'),
    ];
    for (final (id, term, meaning) in seeded) {
      await database.flashcardDao.insertFlashcard(
        id,
        'root',
        term,
        term,
        meaning,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        0,
        0,
      );
    }
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.practice('root'),
      routes: studyRoutes(),
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

  /// A phone-sized surface: the default 800x600 test window puts the CTA
  /// below the fold, and the kit draws this screen at 390 wide.
  Future<void> usePhone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> pumpPicker(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Future<int> activeSessions() async {
    final rows = await database
        .customSelect(
          "SELECT COUNT(*) AS c FROM study_sessions WHERE state = 'active'",
        )
        .get();
    return rows.first.data['c'] as int;
  }

  testWidgets('lists the five practice modes over the deck scope', (
    tester,
  ) async {
    await usePhone(tester);
    await tester.pumpWidget(app());
    await pumpPicker(tester);

    expect(find.text('Practice mode'), findsOneWidget);
    // The scope card names the deck the session would run over.
    expect(find.text('Card source'), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);

    for (final name in ['Review', 'Match', 'Guess', 'Recall', 'Fill']) {
      expect(find.text(name), findsOneWidget, reason: '$name is offered');
    }
    expect(find.text('Start session'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // §6, the rule this screen exists for: "chọn một tile không tự start".
  testWidgets('choosing a mode starts nothing until the CTA', (tester) async {
    await usePhone(tester);
    await tester.pumpWidget(app());
    await pumpPicker(tester);

    await tester.tap(find.text('Match'));
    await pumpPicker(tester);

    expect(await activeSessions(), 0, reason: 'selecting is not starting');

    await tester.tap(find.text('Start session'));
    await pumpPicker(tester);

    expect(await activeSessions(), 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
