import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/usecases/deck/delete_deck_usecase.dart';

/// WBS 6.1 — deleting a deck resolves it then delegates the atomic cascade to
/// the store; a missing deck is a typed failure (delete-deck.md).
void main() {
  final now = DateTime.utc(2026, 7, 24, 13);

  Deck deck() => Deck(
    id: 'd1',
    languagePairId: 'lp1',
    parentId: null,
    name: 'Deck',
    normalizedName: 'deck',
    description: null,
    createdAt: now,
    updatedAt: now,
  );

  test('an existing deck is deleted via the store', () async {
    final repo = _FakeDecks(deck());
    await DeleteDeckUseCase(decks: repo).call('d1');
    expect(repo.deletedId, 'd1');
  });

  test('a missing deck is a typed failure and never deletes', () async {
    final repo = _FakeDecks(null);
    await expectLater(
      DeleteDeckUseCase(decks: repo).call('ghost'),
      throwsA(
        isA<ValidationFailure>().having((f) => f.field, 'field', 'deckId'),
      ),
    );
    expect(repo.deletedId, isNull);
  });

  test('a store failure propagates and reports nothing removed', () async {
    final repo = _FakeDecks(
      deck(),
      deleteError: ConflictFailure(code: 'in-use', entity: 'deck'),
    );
    await expectLater(
      DeleteDeckUseCase(decks: repo).call('d1'),
      throwsA(isA<ConflictFailure>()),
    );
  });
}

class _FakeDecks implements DeckRepository {
  _FakeDecks(this._deck, {this.deleteError});
  final Deck? _deck;
  final Object? deleteError;

  String? deletedId;

  @override
  Future<Deck?> findById(String id) async => _deck;

  @override
  Future<void> delete(String deckId) async {
    if (deleteError != null) throw deleteError!;
    deletedId = deckId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}
