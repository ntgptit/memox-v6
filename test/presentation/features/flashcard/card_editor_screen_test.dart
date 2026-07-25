import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_form_footer.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/screens/card_editor_screen.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_translations_section.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_switch.dart';
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

  /// Reveals the additional-translations slot.
  ///
  /// The kit keeps the resting form Term -> Meaning -> Tags and puts the
  /// translation slot one tap away behind the Meaning label's `+`, so a test
  /// that wants the slot has to ask for it the way a user does.
  Future<void> discloseTranslations(WidgetTester tester) async {
    // Targeted by icon rather than accessible name: while the slot is
    // hidden the Meaning label's `+` is the only add glyph on screen, and
    // its name reaches the tree through `MxTappable`, which
    // `find.bySemanticsLabel` does not see.
    await tester.tap(find.byIcon(Symbols.add_rounded).first);
    await pumpEditor(tester);
  }

  /// Opens the advanced disclosure.
  ///
  /// It sits at the foot of a scrolling form, below the fold on this
  /// viewport, so a bare `tap` hit-tests against whatever is on screen and
  /// silently does nothing.
  /// Gives the form a viewport tall enough to hold it without scrolling.
  ///
  /// The advanced disclosure and its switch sit at the foot of the form, off
  /// the default 600px-tall test view. Scrolling them into place is not enough
  /// on its own: `ensureVisible` stops as soon as the target is technically in
  /// view, and a tap at that position can land on a neighbouring widget while
  /// `warnIfMissed` stays silent — the hit test *did* find something, just not
  /// the target. A taller view removes the geometry from the question.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openMoreOptions(WidgetTester tester) async {
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
  }

  /// Taps the visibility switch and proves it actually flipped.
  ///
  /// Asserting the flip rather than trusting the tap: this control sits at the
  /// foot of a scrolling form behind a sticky footer, exactly where a tap can
  /// silently hit the wrong widget.
  Future<void> toggleHide(WidgetTester tester) async {
    final before = tester.widget<MxSwitch>(find.byType(MxSwitch)).value;
    await tester.tap(find.byType(MxSwitch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MxSwitch>(find.byType(MxSwitch)).value,
      !before,
      reason: 'the tap did not reach the switch',
    );
  }

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  MxButton saveButton(WidgetTester tester) =>
      tester.widget<MxButton>(find.byType(MxButton));

  // KIT-25-04 / 35-01: the kit's `keyboard-open` state exists to pin one
  // behaviour — the sticky Save bar sits directly above the raised keyboard and
  // is never covered by it. That shot cannot be measured here (it draws a
  // simulated software keyboard, which a desktop browser capture has no way to
  // produce), so the contract is asserted instead of photographed.
  testWidgets('the Save bar stays above a raised keyboard', (tester) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    final beforeInset = tester.getRect(find.byType(MxButton));
    expect(
      beforeInset.bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );

    // Raise a keyboard the size of a typical software one.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
    await pumpEditor(tester);

    final visibleBottom =
        tester.view.physicalSize.height / tester.view.devicePixelRatio - 200;
    final afterInset = tester.getRect(find.byType(MxButton));

    // The button moved up rather than being covered: it now sits inside the
    // area the keyboard left behind.
    expect(afterInset.bottom, lessThanOrEqualTo(visibleBottom));
    expect(afterInset.top, lessThan(beforeInset.top));
    expect(find.byType(MxFormFooter), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

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

  // `manage-card-translations.md` §2 lists the entry points as "Create/Edit
  // Card -> Add translation", and the kit's `FlashcardEditor.jsx` hangs the
  // `+` off the Meaning label with no mode gate. It shipped gated on edit, so
  // a card being created had no route to a translation: the learner had to
  // save the card, leave, reopen it and edit. The parity ratio could not catch
  // it — a missing 24px icon is far below the 3% threshold, and MX-VIS-049
  // passes at 1.19% without it.
  testWidgets('the translation slot is reachable while creating a card', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    expect(
      find.byIcon(Symbols.add_rounded),
      findsWidgets,
      reason: 'create mode must offer the add-translation control',
    );

    await discloseTranslations(tester);

    // Term, Meaning, Translation, Tags — the kit's order.
    expect(find.byType(TextField), findsNWidgets(4));

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a translation typed while creating is saved with the card', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await discloseTranslations(tester);
    await tester.enterText(find.byType(TextField).at(2), 'xin chào');
    await tester.pump();

    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    final cards = await database.flashcardDao
        .pageFlashcardsByDeck('d1', 50, 0)
        .get();
    final translations = await database.flashcardDao
        .listTranslationsForCard(cards.single.id)
        .get();
    expect(
      translations.map((t) => t.translationText),
      <String>['xin chào'],
      reason: 'the draft must be written once the card exists',
    );

    await disposeAndFlushStreams(tester);
  });

  // The slot's `close` clears as well as hides. Reopening it must not
  // resurrect dismissed text, which would attach a translation the learner
  // explicitly threw away.
  testWidgets('dismissing the translation slot discards its draft', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await discloseTranslations(tester);
    await tester.enterText(find.byType(TextField).at(2), 'xin chào');
    await tester.pump();

    await tester.tap(find.byIcon(Symbols.close_rounded));
    await pumpEditor(tester);

    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    final cards = await database.flashcardDao
        .pageFlashcardsByDeck('d1', 50, 0)
        .get();
    final translations = await database.flashcardDao
        .listTranslationsForCard(cards.single.id)
        .get();
    expect(translations, isEmpty);

    await disposeAndFlushStreams(tester);
  });

  // Kit `flashcard-editor/more-toggle` + `flashcard-editor/visibility`
  // (WBS 6.5; `hide-flashcard.md`). The whole hide path already existed —
  // column, query, repository, use case, viewmodel, and every due/study query
  // excluding hidden cards — with no way to reach it from the editor. Even the
  // `moreOptionsLabel` string was already in the ARB, unused.
  testWidgets('advanced options stay collapsed until asked for', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    expect(find.text('More options'), findsOneWidget);
    expect(
      find.text('Hide during study'),
      findsNothing,
      reason: 'every kit shot draws the disclosure collapsed',
    );

    await openMoreOptions(tester);

    expect(find.text('Hide during study'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a card can be created already hidden', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(app());
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), '안녕');
    await tester.enterText(find.byType(TextField).at(1), 'hello');
    await openMoreOptions(tester);
    await toggleHide(tester);

    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    final cards = await database.flashcardDao
        .pageFlashcardsByDeck('d1', 50, 0)
        .get();
    // Capture now, study later. The create path hard-coded visible *and* the
    // insert omitted the column entirely, so this was unreachable however the
    // form was filled in. (Drift returns the raw column, hence 1 not true.)
    expect(cards.single.isHidden, 1);

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
    await discloseTranslations(tester);
    await tester.enterText(find.byType(TextField).at(2), 'xin chào');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await pumpEditor(tester);

    // Still on the editor with an empty form.
    expect(find.text('New card'), findsOneWidget);
    final termField = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(termField.controller?.text, isEmpty);
    // The translation slot closes with the rest of the form: a slot left open
    // and populated would attach the previous card's translation to the next.
    expect(find.byType(TextField), findsNWidgets(3));

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
      // term, meaning and add-tag. The translation slot is disclosed, not
      // resting (kit progressive disclosure), so it is not here yet.
      expect(find.byType(TextField), findsNWidgets(3));
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

    Future<List<String>> translationTexts() async {
      final rows = await database
          .customSelect(
            'SELECT translation_text FROM flashcard_translations '
            "WHERE card_id = 'c1' ORDER BY display_order",
          )
          .get();
      return rows.map((r) => r.read<String>('translation_text')).toList();
    }

    testWidgets('adds an additional translation that persists and lists', (
      tester,
    ) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);

      expect(find.text('ADDITIONAL TRANSLATIONS'), findsNothing);
      await discloseTranslations(tester);
      // The overline section header renders in caps once disclosed.
      expect(find.text('ADDITIONAL TRANSLATIONS'), findsOneWidget);
      // term, meaning, and the add-translation field.
      await tester.enterText(find.byType(TextField).at(2), 'goodbye');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(CardTranslationsSection),
          matching: find.byIcon(Symbols.add_rounded),
        ),
      );
      await pumpEditor(tester);

      expect(await translationTexts(), ['goodbye']);
      expect(find.text('goodbye'), findsOneWidget);

      await disposeAndFlushStreams(tester);
    });

    testWidgets('removes an additional translation', (tester) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);
      await discloseTranslations(tester);

      await tester.enterText(find.byType(TextField).at(2), 'goodbye');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(CardTranslationsSection),
          matching: find.byIcon(Symbols.add_rounded),
        ),
      );
      await pumpEditor(tester);
      expect(await translationTexts(), ['goodbye']);

      await tester.tap(find.bySemanticsLabel('Remove translation'));
      await pumpEditor(tester);

      expect(await translationTexts(), isEmpty);

      await disposeAndFlushStreams(tester);
    });

    testWidgets('a blank translation is rejected', (tester) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);
      await discloseTranslations(tester);

      // The add control stays disabled with no text (nothing to persist).
      await tester.enterText(find.byType(TextField).at(2), '   ');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(CardTranslationsSection),
          matching: find.byIcon(Symbols.add_rounded),
        ),
      );
      await pumpEditor(tester);

      expect(await translationTexts(), isEmpty);

      await disposeAndFlushStreams(tester);
    });

    Future<List<String>> tagNames() async {
      final rows = await database
          .customSelect(
            'SELECT t.name AS name FROM tags t '
            'JOIN flashcard_tags ct ON ct.tag_id = t.id '
            "WHERE ct.card_id = 'c1' ORDER BY t.name",
          )
          .get();
      return rows.map((r) => r.read<String>('name')).toList();
    }

    /// Commits the typed tag.
    ///
    /// The kit's `TagsField` is a single bordered row — glyph, chips and
    /// caret on one surface — with no separate add button, so a tag is
    /// committed by submitting the entry.
    Future<void> submitTag(WidgetTester tester) async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpEditor(tester);
    }

    testWidgets('attaches a tag chip that persists', (tester) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);

      // term, meaning, add-tag — the tag field is last, and the translation
      // slot is not resting in the form (kit progressive disclosure).
      await tester.enterText(find.byType(TextField).at(2), 'grammar');
      await tester.pump();
      await submitTag(tester);

      expect(await tagNames(), ['grammar']);
      expect(find.text('grammar'), findsOneWidget);

      await disposeAndFlushStreams(tester);
    });

    testWidgets('removes a tag by tapping its chip', (tester) async {
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);

      await tester.enterText(find.byType(TextField).at(2), 'grammar');
      await tester.pump();
      await submitTag(tester);
      expect(await tagNames(), ['grammar']);

      await tester.ensureVisible(find.text('grammar'));
      await tester.tap(find.text('grammar'));
      await pumpEditor(tester);

      expect(await tagNames(), isEmpty);

      await disposeAndFlushStreams(tester);
    });

    // On a stored card the toggle is its own action, not part of the draft:
    // `hide-flashcard.md` §1 makes it idempotent and needs no confirm, and it
    // must not wait on Save — which in edit mode stays disabled until the
    // *content* is dirty, so a deferred toggle could never be committed.
    testWidgets('toggling hide commits immediately on a stored card', (
      tester,
    ) async {
      useTallViewport(tester);
      await seedCard();
      await tester.pumpWidget(editApp('c1'));
      await pumpEditor(tester);

      await openMoreOptions(tester);
      await toggleHide(tester);

      final card = await database.flashcardDao
          .findFlashcardById('c1')
          .getSingleOrNull();
      expect(card?.isHidden, 1);

      await disposeAndFlushStreams(tester);
    });
  });
}
