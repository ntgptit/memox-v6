import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/usecases/deck/rename_deck_usecase.dart';

/// WBS 6.1 — renaming a deck trims + validates the name, calls the store's
/// rename with the normalized form, and surfaces typed failures (edit-deck.md).
void main() {
  final now = DateTime.utc(2026, 7, 24, 11);

  Deck deck() => Deck(
    id: 'd1',
    languagePairId: 'lp1',
    parentId: null,
    name: 'Old name',
    normalizedName: 'old name',
    description: null,
    createdAt: now,
    updatedAt: now,
  );

  test(
    'a valid rename persists the trimmed display + normalized name',
    () async {
      final repo = _FakeDecks(deck());
      await RenameDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'd1', name: '  Korean TOPIK I  ');

      expect(repo.renamedId, 'd1');
      expect(repo.renamedName, 'Korean TOPIK I');
      expect(repo.renamedNormalized, 'korean topik i');
      expect(repo.renamedAt, now);
    },
  );

  test('an empty name is rejected before any store call', () async {
    final repo = _FakeDecks(deck());
    await expectLater(
      RenameDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'd1', name: '   '),
      throwsA(
        isA<ValidationFailure>()
            .having((f) => f.field, 'field', 'deckName')
            .having((f) => f.code, 'code', 'required'),
      ),
    );
    expect(repo.renamedId, isNull);
  });

  test('a missing deck is a typed failure and never renames', () async {
    final repo = _FakeDecks(null);
    await expectLater(
      RenameDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'ghost', name: 'New name'),
      throwsA(
        isA<ValidationFailure>().having((f) => f.field, 'field', 'deckId'),
      ),
    );
    expect(repo.renamedId, isNull);
  });

  test('a sibling-name collision propagates the store conflict', () async {
    final repo = _FakeDecks(
      deck(),
      renameError: ConflictFailure(code: 'duplicate', entity: 'deck'),
    );
    await expectLater(
      RenameDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'd1', name: 'Sibling'),
      throwsA(isA<ConflictFailure>()),
    );
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _FakeDecks implements DeckRepository {
  _FakeDecks(this._deck, {this.renameError});
  final Deck? _deck;
  final Object? renameError;

  String? renamedId;
  String? renamedName;
  String? renamedNormalized;
  DateTime? renamedAt;

  @override
  Future<Deck?> findById(String id) async => _deck;

  @override
  Future<void> rename(
    String deckId, {
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  }) async {
    if (renameError != null) throw renameError!;
    renamedId = deckId;
    renamedName = name;
    renamedNormalized = normalizedName;
    renamedAt = updatedAt;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}
