import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:memox_v6/domain/search/search_target.dart';

/// Revalidates a search result immediately before navigation
/// (`open-search-result.md` §1, §2).
///
/// §1: "Stable id là nguồn resolve; display text/path chỉ hỗ trợ nhận biết"
/// and "Object được revalidate ngay trước navigation". The list is a snapshot
/// of the index when the query ran; between then and the tap the object can be
/// deleted, hidden or moved. Opening it on the strength of the cached row is
/// exactly what §6 forbids — "Không mở object chỉ dựa vào text/path cũ".
class ResolveSearchResultUseCase {
  const ResolveSearchResultUseCase({
    required FlashcardRepository cards,
    required DeckRepository decks,
  }) : _cards = cards,
       _decks = decks;

  final FlashcardRepository _cards;
  final DeckRepository _decks;

  /// [includeHidden] is the visibility filter the list was built with. A
  /// learner who asked for hidden cards is not surprised to open one; a
  /// learner who did not would be opening something the list should no longer
  /// be showing.
  Future<SearchTargetResolution> call(
    SearchResult result, {
    required bool includeHidden,
  }) async {
    if (result.type == SearchResultType.deck) {
      final deck = await _decks.findById(result.id);
      if (deck == null) {
        return const SearchTargetGone(SearchTargetGoneReason.deleted);
      }
      return SearchTargetReady(deckId: deck.id, moved: false);
    }

    final card = await _cards.findById(result.id);
    if (card == null || card.isDeleted) {
      return const SearchTargetGone(SearchTargetGoneReason.deleted);
    }
    if (card.isHidden && !includeHidden) {
      return const SearchTargetGone(SearchTargetGoneReason.hidden);
    }
    return SearchTargetReady(
      deckId: card.deckId,
      moved: card.deckId != result.deckId,
    );
  }
}
