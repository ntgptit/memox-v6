import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/today/add_card_target.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';

/// Resolves where a card created from Today's create sheet would go
/// (WBS 5.7.2; `manage-today-create-actions.md` §2 node C).
///
/// §6: "Add Card không bypass target eligibility." A Parent deck holds
/// subdecks rather than cards, so it is not a target — the check is
/// `countSubtreeDecks`, not the deck's own row.
///
/// Only root decks are considered. A nested Leaf is a perfectly good target,
/// but reaching one means walking the tree, and the surface that walks it is
/// the kit's own `add-card-target` screen, which does not exist yet. Offering
/// the Library instead of guessing is the honest interim.
class ResolveAddCardTargetUseCase {
  const ResolveAddCardTargetUseCase({
    required DeckRepository decks,
    required SelectLanguagePairUseCase languagePairs,
  }) : _decks = decks,
       _languagePairs = languagePairs;

  final DeckRepository _decks;
  final SelectLanguagePairUseCase _languagePairs;

  Future<AddCardTarget> call() async {
    final pair = await _languagePairs.activePair();
    if (pair == null) return const NoAddCardTarget();

    final roots = await _decks.watchRoots(pair.id).first;
    if (roots.isEmpty) return const NoAddCardTarget();
    if (roots.length > 1) return const ChooseAddCardTarget();

    // One root: it is a target only if it holds no subdecks. A Parent with a
    // single child is still a Parent, and a card added to it would sit beside
    // decks rather than inside one — but its children may well be Leaves, so
    // the answer is "choose", not "create a deck first".
    final nested = await _decks.countSubtreeDecks(roots.single.id);
    if (nested > 0) return const ChooseAddCardTarget();
    return SingleAddCardTarget(roots.single.id);
  }
}
