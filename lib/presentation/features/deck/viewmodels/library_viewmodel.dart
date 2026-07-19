import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_viewmodel.g.dart';

/// Library root state (WBS 5.2.4A).

/// Root decks of the active language pair, reactive: creates/renames/
/// moves re-emit through the repository stream. No active pair yields
/// an empty library.
@riverpod
Stream<List<Deck>> libraryRootDecks(Ref ref) async* {
  final pair = await ref.watch(selectLanguagePairUseCaseProvider).activePair();
  if (pair == null) {
    yield const <Deck>[];
    return;
  }
  yield* ref.watch(watchLibraryUseCaseProvider).rootsOf(pair.id);
}

/// The transferred first-run success callout (`create-deck.md` §7):
/// success lands in the Library with the new deck highlighted and this
/// dismissible callout. Keep-alive so the state survives the
/// navigation from step 2 into the Library; cleared on dismiss/open.
@Riverpod(keepAlive: true)
class FirstDeckCalloutViewmodel extends _$FirstDeckCalloutViewmodel {
  @override
  String? build() => null;

  void showForDeck(String deckId) => state = deckId;

  void dismissCallout() => state = null;
}
