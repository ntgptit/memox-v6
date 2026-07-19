import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';

/// Removes a language pair behind the Deck dependency guard
/// (WBS 5.1.1; `remove-language-pair.md`).
///
/// A pair that still owns decks never deletes —
/// `ConflictFailure(code: 'deck-dependency')` sends the flow to its
/// explicit resolution instead. Removing the active pair also clears
/// the stored selection so no stale id survives.
class RemoveLanguagePairUseCase {
  const RemoveLanguagePairUseCase({
    required LanguagePairRepository pairs,
    required DeckRepository decks,
    required PreferenceRepository preferences,
  }) : _pairs = pairs,
       _decks = decks,
       _preferences = preferences;

  final LanguagePairRepository _pairs;
  final DeckRepository _decks;
  final PreferenceRepository _preferences;

  Future<void> call(String pairId) async {
    final deckCount = await _decks.countForLanguagePair(pairId);
    if (deckCount > 0) {
      throw ConflictFailure(code: 'deck-dependency', entity: 'language_pairs');
    }

    final selection = await _preferences.read(
      SelectLanguagePairUseCase.preferenceKey,
    );
    if (selection?.value == pairId) {
      await _preferences.remove(SelectLanguagePairUseCase.preferenceKey);
    }

    await _pairs.deleteById(pairId);
  }
}
