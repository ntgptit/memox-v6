import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';

/// WBS 6.1 — the delete impact derives the deck state and totals the subtree it
/// would remove (delete-deck.md §4).
void main() {
  LoadDeckDeletionImpactUseCase build({
    required int directChildren,
    required int directCards,
    required int subtreeCards,
    required int subtreeDecks,
  }) => LoadDeckDeletionImpactUseCase(
    decks: _FakeDecks(
      counts: DeckContentCounts(
        childDeckCount: directChildren,
        activeCardCount: directCards,
      ),
      subtreeCards: subtreeCards,
      subtreeDecks: subtreeDecks,
    ),
  );

  test('an empty deck reports the empty state with zero totals', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 0,
      subtreeCards: 0,
      subtreeDecks: 0,
    ).call('d1');
    expect(impact.state, DeckContentState.empty);
    expect(impact.cardCount, 0);
    expect(impact.deckCount, 0);
  });

  test('a leaf reports its card total', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 4,
      subtreeCards: 4,
      subtreeDecks: 0,
    ).call('d1');
    expect(impact.state, DeckContentState.leaf);
    expect(impact.cardCount, 4);
    expect(impact.deckCount, 0);
  });

  test('a parent reports nested decks + subtree cards', () async {
    final impact = await build(
      directChildren: 2,
      directCards: 0,
      subtreeCards: 9,
      subtreeDecks: 3,
    ).call('d1');
    expect(impact.state, DeckContentState.parent);
    expect(impact.cardCount, 9);
    expect(impact.deckCount, 3);
  });
}

class _FakeDecks implements DeckRepository {
  _FakeDecks({
    required this.counts,
    required this.subtreeCards,
    required this.subtreeDecks,
  });
  final DeckContentCounts counts;
  final int subtreeCards;
  final int subtreeDecks;

  @override
  Future<DeckContentCounts> contentCounts(String deckId) async => counts;
  @override
  Future<int> countSubtreeCards(String deckId) async => subtreeCards;
  @override
  Future<int> countSubtreeDecks(String deckId) async => subtreeDecks;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}
