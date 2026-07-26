import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/today/add_card_target.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/today/resolve_add_card_target_usecase.dart';

/// WBS 5.7.2 — `manage-today-create-actions.md` §6: "Add Card không bypass
/// target eligibility."
void main() {
  final now = DateTime.utc(2026, 7, 26);

  final pair = LanguagePair(
    id: 'lp1',
    learningLanguageCode: 'en',
    nativeLanguageCode: 'vi',
    normalizedPairKey: 'en|vi',
    createdAt: now,
    updatedAt: now,
  );

  Deck deck(String id) => Deck(
    id: id,
    languagePairId: 'lp1',
    parentId: null,
    name: id,
    normalizedName: id,
    createdAt: now,
    updatedAt: now,
  );

  ResolveAddCardTargetUseCase build({
    LanguagePair? activePair,
    List<Deck> roots = const <Deck>[],
    int nested = 0,
  }) => ResolveAddCardTargetUseCase(
    decks: _FakeDecks(roots, nested),
    languagePairs: _StubPairs(activePair),
  );

  test('one childless root is the target', () async {
    final target = await build(activePair: pair, roots: <Deck>[deck('d1')])();

    expect(target, isA<SingleAddCardTarget>());
    expect((target as SingleAddCardTarget).deckId, 'd1');
  });

  // A Parent holds subdecks, not cards. Its children may be Leaves, so the
  // answer is "choose", not "make a deck first".
  test('a lone Parent asks which of its decks', () async {
    final target = await build(
      activePair: pair,
      roots: <Deck>[deck('d1')],
      nested: 3,
    )();

    expect(target, isA<ChooseAddCardTarget>());
  });

  test('several roots ask rather than guess', () async {
    final target = await build(
      activePair: pair,
      roots: <Deck>[deck('d1'), deck('d2')],
    )();

    expect(target, isA<ChooseAddCardTarget>());
  });

  test('an empty library has nowhere to put a card', () async {
    final target = await build(activePair: pair)();

    expect(target, isA<NoAddCardTarget>());
  });

  test('no active pair has nowhere either', () async {
    final target = await build(roots: <Deck>[deck('d1')])();

    expect(target, isA<NoAddCardTarget>());
  });
}

class _FakeDecks implements DeckRepository {
  _FakeDecks(this._roots, this._nested);

  final List<Deck> _roots;
  final int _nested;

  @override
  Stream<List<Deck>> watchRoots(String languagePairId) =>
      Stream<List<Deck>>.value(_roots);

  @override
  Future<int> countSubtreeDecks(String deckId) async => _nested;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPairs implements SelectLanguagePairUseCase {
  _StubPairs(this._pair);

  final LanguagePair? _pair;

  @override
  Future<LanguagePair?> activePair() async => _pair;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
