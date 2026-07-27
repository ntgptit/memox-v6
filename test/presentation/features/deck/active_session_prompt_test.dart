import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_quick_study_action.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_start_notifier.dart';

/// WBS 5.6.1 — starting a session while one is running is a fork, not an
/// error, and `start-study-session.md` §5 asks the prompt to name the deck the
/// running session belongs to before offering Resume.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
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
    for (final (id, name) in const <(String, String)>[
      ('d1', 'Korean verbs'),
      ('d2', 'Korean nouns'),
    ]) {
      await database.deckDao.insertDeck(
        id,
        'lp1',
        null,
        name,
        name.toLowerCase(),
        0,
        0,
      );
    }
    // Five new cards in each deck, so either could start a session.
    for (final deck in const <String>['d1', 'd2']) {
      for (var i = 0; i < 5; i++) {
        final id = '$deck-c$i';
        await database.flashcardDao.insertFlashcard(
          id,
          deck,
          'term-$id',
          'term-$id',
          'meaning-$id',
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
    }
  });

  /// A screen carrying the listener, so the prompt has somewhere to open.
  Widget app() => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _StudyStartHost(),
    ),
  );

  testWidgets('the resume prompt names the deck the session is in', (
    tester,
  ) async {
    // A session left running in one deck.
    await container
        .read(startStudySessionUseCaseProvider)
        .call(
          deckId: 'd1',
          scope: SessionScope.subtree,
          type: SessionType.newLearning,
        );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Studying the other deck hits the one-active-session rule.
    await tester.tap(find.text('Study the other deck'));
    await tester.pumpAndSettle();

    expect(find.text('Continue your session?'), findsOneWidget);
    expect(
      find.text(
        'Your session in Korean verbs is still in progress. Resume it to keep going.',
      ),
      findsOneWidget,
      reason: '§5 asks the prompt to name the deck before offering Resume',
    );
  });
}

/// Mounts the quick-study listener and one control that starts `d2`.
class _StudyStartHost extends ConsumerWidget {
  const _StudyStartHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForQuickStudyStart(ref, context);
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              ref.read(studyStartProvider.notifier).start(deckId: 'd2'),
          child: const Text('Study the other deck'),
        ),
      ),
    );
  }
}
