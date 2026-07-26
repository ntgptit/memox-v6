import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';

/// WBS 5.6 — answering the last card of a session opens the Result screen.
///
/// Every layer under this was tested and every layer was right. What nobody
/// drove was the whole thing at once: the dispatcher, the mode screen, the
/// answer command, the store, the re-read that follows every answer, and
/// finalize. `int-44` lived exactly there — the checkpoint could not carry the
/// complete phase, so the re-read handed back a session sitting on the card
/// just answered. The learner would have been asked it again, forever, and no
/// session could ever finish.
///
/// It runs on a real database with the real providers: nothing here is faked
/// except the screen's size.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  final dueAt = DateTime.utc(2026, 7, 26, 9);

  setUp(() async {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
    for (final (id, term, meaning) in const <(String, String, String)>[
      ('c1', '학교', 'school'),
      ('c2', '친구', 'friend'),
    ]) {
      await database.flashcardDao.insertFlashcard(
        id,
        'd1',
        term,
        term,
        meaning,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        3,
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  });

  Widget app() => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StudySessionScreen(),
    ),
  );

  Future<SessionState> sessionState() async {
    final row = await database
        .customSelect('SELECT state FROM study_sessions')
        .getSingle();
    return SessionState.parse(row.read<String>('state'));
  }

  testWidgets('answering the last card opens the result', (tester) async {
    await container
        .read(startStudySessionUseCaseProvider)
        .call(
          deckId: 'd1',
          scope: SessionScope.subtree,
          type: SessionType.dueReview,
        );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Two due cards, so two answers. Which card comes first is the committed
    // order's business, not this test's.
    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();
    expect(
      find.text('Remembered'),
      findsOneWidget,
      reason: 'the second card is up',
    );

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'both cards reviewed');
    expect(find.text('100%'), findsOneWidget);
    expect(await sessionState(), SessionState.completed);
  });

  // The other half of the same loop: a card answered wrong comes back in the
  // retry round rather than ending the session.
  testWidgets('a wrong answer keeps the session going', (tester) async {
    await container
        .read(startStudySessionUseCaseProvider)
        .call(
          deckId: 'd1',
          scope: SessionScope.subtree,
          type: SessionType.dueReview,
        );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relearn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(
      find.text('Session complete'),
      findsNothing,
      reason: 'the missed card opens a retry round',
    );
    expect(find.text('Remembered'), findsOneWidget);
    expect(await sessionState(), SessionState.active);
  });
}
