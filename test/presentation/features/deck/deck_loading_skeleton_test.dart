import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/screens/deck_detail_screen.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_skeleton.dart';

/// WBS 3.x shared gap + `MX-VIS-037` / `MX-VIS-043`: the deck-detail loading
/// states render the kit's skeleton placeholders, and which of the two kit
/// compositions appears is derived from the resolved child decks.
void main() {
  const deckId = 'deck-1';

  final deck = Deck(
    id: deckId,
    languagePairId: 'lp1',
    parentId: null,
    name: 'Travel',
    normalizedName: 'travel',
    createdAt: DateTime.utc(2026, 7, 25),
    updatedAt: DateTime.utc(2026, 7, 25),
  );

  final childDeck = Deck(
    id: 'child-1',
    languagePairId: 'lp1',
    parentId: deckId,
    name: 'Airport',
    normalizedName: 'airport',
    createdAt: DateTime.utc(2026, 7, 25),
    updatedAt: DateTime.utc(2026, 7, 25),
  );

  /// Hosts the screen with each async input pinned to a chosen state. A
  /// `null` stream stays pending, which is the state under test.
  Widget host({
    required Stream<List<Deck>>? children,
    required Stream<List<Flashcard>>? cards,
  }) {
    return ProviderScope(
      overrides: [
        deckDetailProvider(deckId: deckId).overrideWith((ref) async => deck),
        deckChildrenProvider(
          deckId: deckId,
        ).overrideWith((ref) => children ?? const Stream<List<Deck>>.empty()),
        deckCardsProvider(
          deckId: deckId,
        ).overrideWith((ref) => cards ?? const Stream<List<Flashcard>>.empty()),
        deckBreadcrumbProvider(deckId: deckId).overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeckDetailScreen(deckId: deckId),
      ),
    );
  }

  /// A stream that never emits, so its provider stays in `AsyncLoading`.
  Stream<T> pending<T>() => StreamController<T>().stream;

  testWidgets(
    'the leaf branch loading state is the kit flashcard-list composition',
    (tester) async {
      await tester.pumpWidget(
        host(
          // Resolved with no child decks → leaf-or-empty.
          children: Stream<List<Deck>>.value(const <Deck>[]),
          cards: pending<List<Flashcard>>(),
        ),
      );
      // Two pumps: the first resolves the deck future, the second lets the
      // children stream deliver so the branch is derivable.
      await tester.pump();
      await tester.pump();

      // Kit: five card rows, each with a trailing 56×22 badge pill and no
      // leading round tile.
      expect(find.byType(MxCard), findsNWidgets(5));
      expect(
        tester
            .widgetList<MxSkeleton>(find.byType(MxSkeleton))
            .where((s) => s.width == 56 && s.height == 22)
            .length,
        5,
      );
      // The filter-row placeholder is the taller 44 pill on this branch.
      expect(
        tester
            .widgetList<MxSkeleton>(find.byType(MxSkeleton))
            .where((s) => s.height == 44)
            .length,
        1,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'the parent branch loading state is the kit subdeck-list composition',
    (tester) async {
      await tester.pumpWidget(
        host(
          // Resolved WITH a child deck → parent branch.
          children: Stream<List<Deck>>.value(<Deck>[childDeck]),
          cards: pending<List<Flashcard>>(),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Kit: four deck rows, each led by a 40×40 round tile.
      expect(find.byType(MxCard), findsNWidgets(4));
      expect(
        tester
            .widgetList<MxSkeleton>(find.byType(MxSkeleton))
            .where((s) => s.width == 40 && s.height == 40)
            .length,
        4,
      );
      // The shorter 40 filter pill distinguishes it from the leaf branch.
      expect(
        tester
            .widgetList<MxSkeleton>(find.byType(MxSkeleton))
            .where((s) => s.height == 40 && s.width == null)
            .length,
        1,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('an unresolved branch falls back to the deck-row shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(children: pending<List<Deck>>(), cards: pending<List<Flashcard>>()),
    );
    await tester.pump();

    // Nothing is known yet, so the kit's deck-row placeholder stands in.
    expect(find.byType(MxCard), findsNWidgets(4));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the loading states no longer fall back to a spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(children: pending<List<Deck>>(), cards: pending<List<Flashcard>>()),
    );
    await tester.pump();

    expect(find.byType(MxProgress), findsNothing);
    expect(find.byType(MxSkeleton), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
