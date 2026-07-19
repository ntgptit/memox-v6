import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Reactive Library reads (WBS 5.2.4A): the root decks of one language
/// pair, ordered by normalized name (the repository stream contract).
class WatchLibraryUseCase {
  const WatchLibraryUseCase({required DeckRepository decks}) : _decks = decks;

  final DeckRepository _decks;

  Stream<List<Deck>> rootsOf(String languagePairId) {
    return _decks.watchRoots(languagePairId);
  }
}
