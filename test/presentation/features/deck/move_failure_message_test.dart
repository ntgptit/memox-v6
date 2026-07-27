import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/move_destination.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/move_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/widgets/move_deck_dialog.dart';

/// `move-deck.md` §7 and §8 — a failed move says which rule stopped it, and
/// says that nothing moved.
///
/// The sheet showed the shared error surface, which only reports that
/// something went wrong. §1 promises the move is atomic; §8's middle sentence
/// is where a learner is told so.
void main() {
  Widget host(AsyncValue<void> moveState) => ProviderScope(
    overrides: [
      deckMoveDestinationsProvider(deckId: 'd1').overrideWith(
        (ref) => Future.value(<MoveDestination>[
          MoveDestination(deck: _deck('other')),
        ]),
      ),
      moveDeckDialogViewmodelProvider.overrideWith(() => _FixedMove(moveState)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showMoveDeckSheet(context, deckId: 'd1', deckName: 'Deck'),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester, AsyncValue<void> state) async {
    await tester.pumpWidget(host(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a plain failure says nothing has changed', (tester) async {
    await open(
      tester,
      AsyncError<void>(
        const UnexpectedFailure(cause: 'store down'),
        StackTrace.empty,
      ),
    );

    expect(
      find.text("Couldn't move the deck. Nothing has changed. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('a name collision says so in the destination context', (
    tester,
  ) async {
    await open(
      tester,
      AsyncError<void>(
        ConflictFailure(code: 'duplicate', entity: 'decks'),
        StackTrace.empty,
      ),
    );

    expect(
      find.text('A deck with this name already exists there.'),
      findsOneWidget,
    );
  });

  testWidgets('a leaf destination names the rule that stopped it', (
    tester,
  ) async {
    await open(
      tester,
      AsyncError<void>(
        ConflictFailure(code: 'deck-mixed-content', entity: 'decks'),
        StackTrace.empty,
      ),
    );

    expect(
      find.text("This deck contains cards and can't receive a nested deck."),
      findsOneWidget,
    );
  });

  // The picker filters these out, so reaching one means the tree changed under
  // the sheet — §10's "Destination thành Leaf/bị xóa trước submit".
  testWidgets('a destination that vanished asks for another', (tester) async {
    await open(
      tester,
      AsyncError<void>(
        ValidationFailure(field: 'newParentId', code: 'not-found'),
        StackTrace.empty,
      ),
    );

    expect(
      find.text('That destination is no longer available. Choose another one.'),
      findsOneWidget,
    );
  });
}

Deck _deck(String id) => Deck(
  id: id,
  languagePairId: 'lp1',
  parentId: null,
  name: id,
  normalizedName: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _FixedMove extends MoveDeckDialogViewmodel {
  _FixedMove(this._state);
  final AsyncValue<void> _state;
  @override
  AsyncValue<void> build() => _state;
}
