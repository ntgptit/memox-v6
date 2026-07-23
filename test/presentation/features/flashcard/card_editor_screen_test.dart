import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/screens/card_editor_screen.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'ko',
      'en',
      'ko|en',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Beginner Grammar',
      'beginner grammar',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CardEditorScreen(deckId: 'd1'),
      ),
    );
  }

  Widget editApp(String cardId) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CardEditorScreen(deckId: 'd1', cardId: cardId),
      ),
    );
  }

  Future<void> pumpEditor(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  MxButton saveButton(WidgetTester tester) =>
      tester.widget<MxButton>(find.byType(MxButton));

  testWidgets('renders deck context and deck-driven labels', (tester) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    expect(find.text('New card'), findsOneWidget);
    expect(find.text('Beginner Grammar'), findsOneWidget);
    expect(find.textContaining('한국어'), findsOneWidget);
    expect(find.textContaining('English'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('save stays gated until both required fields have text', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('save creates the card with resolved tags and pops', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), ' 안녕 ');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await tester.enterText(find.byType(TextField).at(2), '#TOPIK_I, grammar');
    await tester.pump();

    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    final cards = await database.flashcardDao
        .pageFlashcardsByDeck('d1', 50, 0)
        .get();
    expect(cards.single.term, '안녕');

    final tags = await database.flashcardDao
        .listTagsForCard(cards.single.id)
        .get();
    expect(tags.map((t) => t.name).toSet(), {'TOPIK_I', 'grammar'});

    await disposeAndFlushStreams(tester);
  });

  testWidgets('create another keeps the editor open and clears the form', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.tap(find.text('Create another card after saving'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    // Still on the editor with an empty form.
    expect(find.text('New card'), findsOneWidget);
    final termField = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(termField.controller?.text, isEmpty);

    final cards = await database.flashcardDao
        .pageFlashcardsByDeck('d1', 50, 0)
        .get();
    expect(cards, hasLength(1));

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a duplicate pauses for review; Add anyway keeps both', (
    tester,
  ) async {
    await database.flashcardDao.insertFlashcard(
      'c0',
      'd1',
      '안녕',
      '안녕',
      'hi',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    // Review banner up, nothing committed yet.
    expect(find.textContaining('already exists'), findsOneWidget);
    var cards = await database.flashcardDao
        .pageFlashcardsByDeck('d1', 50, 0)
        .get();
    expect(cards, hasLength(1));

    await tester.tap(find.text('Add anyway'));
    await pumpEditor(tester);

    cards = await database.flashcardDao.pageFlashcardsByDeck('d1', 50, 0).get();
    expect(cards, hasLength(2));

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a save failure keeps the draft and offers Try again', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await tester.pump();

    await database.customStatement('DROP TABLE learning_progress');
    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    expect(find.textContaining('Couldn’t save the card'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final termField = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(termField.controller?.text, '안녕');

    await disposeAndFlushStreams(tester);
  });

  testWidgets('clearing a touched required field shows the kit error', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '');
    await tester.pump();

    expect(find.text('Enter a term.'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a dirty close asks before discarding', (tester) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Discard this card?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('New card'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  group('edit mode (WBS 6.3; edit-flashcard.md)', () {
    Future<void> seedCard() async {
      await database.flashcardDao.insertFlashcard(
        'c1',
        'd1',
        '안녕',
        '안녕',
        'hi',
        0,
        0,
      );
    }

    testWidgets('prefills the card and keeps a clean Save disabled', (
      tester,
    ) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);

      expect(find.text('Edit card'), findsOneWidget);
      // Two fields only — tags are the manage-card-tags flow, not shown here.
      expect(find.byType(TextField), findsNWidgets(2));
      final termField = tester.widget<TextField>(find.byType(TextField).at(0));
      final meaningField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(termField.controller?.text, '안녕');
      expect(meaningField.controller?.text, 'hi');
      // A clean edit cannot save (edit-flashcard.md §6).
      expect(saveButton(tester).onPressed, isNull);

      await disposeAndFlushStreams(tester);
    });

    testWidgets('editing content rewrites the card and bumps the version', (
      tester,
    ) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);

      await tester.enterText(find.byType(TextField).at(1), 'hello');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Save'));
      await pumpEditor(tester);

      final row = await database.flashcardDao
          .findFlashcardById('c1')
          .getSingle();
      expect(row.primaryMeaning, 'hello');
      expect(row.contentVersion, 2);

      await disposeAndFlushStreams(tester);
    });

    testWidgets('a deleted card shows the not-found notice', (tester) async {
      await tester.pumpWidget(editApp('ghost'));
      await pumpEditor(tester);

      expect(find.text('This card is no longer available.'), findsOneWidget);

      await disposeAndFlushStreams(tester);
    });
  });
}
