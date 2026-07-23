import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/usecases/deck/move_deck_usecase.dart';

/// WBS 6.1 — moving a deck resolves the deck + target then delegates to the
/// store, whose atomic conflict contract owns cycle/mixed-content/duplicate
/// (move-deck.md).
void main() {
  final now = DateTime.utc(2026, 7, 24, 12);

  Deck deck(String id, {String? parentId}) => Deck(
    id: id,
    languagePairId: 'lp1',
    parentId: parentId,
    name: id,
    normalizedName: id,
    description: null,
    createdAt: now,
    updatedAt: now,
  );

  test(
    'a move under a parent resolves both and delegates to the store',
    () async {
      final repo = _FakeDecks({'d1': deck('d1'), 'p1': deck('p1')});
      await MoveDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'd1', newParentId: 'p1');

      expect(repo.movedId, 'd1');
      expect(repo.movedParent, 'p1');
      expect(repo.movedAt, now);
    },
  );

  test('a null target moves the deck to the Library root', () async {
    final repo = _FakeDecks({'d1': deck('d1', parentId: 'p1')});
    await MoveDeckUseCase(
      decks: repo,
      clock: _FixedClock(now),
    ).call(deckId: 'd1', newParentId: null);

    expect(repo.movedId, 'd1');
    expect(repo.movedParent, isNull);
    expect(repo.moveCalls, 1);
  });

  test('a missing deck is a typed failure and never moves', () async {
    final repo = _FakeDecks(const {});
    await expectLater(
      MoveDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'ghost', newParentId: 'p1'),
      throwsA(
        isA<ValidationFailure>().having((f) => f.field, 'field', 'deckId'),
      ),
    );
    expect(repo.moveCalls, 0);
  });

  test('a missing target parent is a typed failure and never moves', () async {
    final repo = _FakeDecks({'d1': deck('d1')});
    await expectLater(
      MoveDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'd1', newParentId: 'ghost'),
      throwsA(
        isA<ValidationFailure>().having((f) => f.field, 'field', 'newParentId'),
      ),
    );
    expect(repo.moveCalls, 0);
  });

  test('destinationsFor delegates to the store with the pair scope', () async {
    final repo = _FakeDecks({'d1': deck('d1')})
      ..destinations = [deck('p1'), deck('p2')];
    final result = await MoveDeckUseCase(
      decks: repo,
      clock: _FixedClock(now),
    ).destinationsFor(deckId: 'd1', languagePairId: 'lp1');

    expect(result.map((d) => d.id), ['p1', 'p2']);
    expect(repo.destinationsPair, 'lp1');
    expect(repo.destinationsMovingId, 'd1');
  });

  test('a cyclic move surfaces the store conflict', () async {
    final repo = _FakeDecks({
      'd1': deck('d1'),
      'p1': deck('p1'),
    }, moveError: ConflictFailure(code: 'deck-cycle', entity: 'deck'));
    await expectLater(
      MoveDeckUseCase(
        decks: repo,
        clock: _FixedClock(now),
      ).call(deckId: 'd1', newParentId: 'p1'),
      throwsA(
        isA<ConflictFailure>().having((f) => f.code, 'code', 'deck-cycle'),
      ),
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
  _FakeDecks(this._decks, {this.moveError});
  final Map<String, Deck> _decks;
  final Object? moveError;

  int moveCalls = 0;
  String? movedId;
  String? movedParent;
  DateTime? movedAt;

  List<Deck> destinations = const [];
  String? destinationsPair;
  String? destinationsMovingId;

  @override
  Future<Deck?> findById(String id) async => _decks[id];

  @override
  Future<List<Deck>> moveDestinations(
    String languagePairId, {
    required String movingDeckId,
  }) async {
    destinationsPair = languagePairId;
    destinationsMovingId = movingDeckId;
    return destinations;
  }

  @override
  Future<void> move(
    String deckId, {
    required String? newParentId,
    required DateTime updatedAt,
  }) async {
    if (moveError != null) throw moveError!;
    moveCalls++;
    movedId = deckId;
    movedParent = newParentId;
    movedAt = updatedAt;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}
