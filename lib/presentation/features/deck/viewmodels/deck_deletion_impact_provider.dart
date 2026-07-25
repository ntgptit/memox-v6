import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck_deletion_impact.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_deletion_impact_provider.g.dart';

/// The delete impact for a deck (WBS 6.1; `delete-deck.md` §4). The confirm
/// dialog reads it to render the Empty/Leaf/Parent copy with the subtree card +
/// nested-deck totals — the widget never touches a repository.
@riverpod
Future<DeckDeletionImpact> deckDeletionImpact(
  Ref ref, {
  required String deckId,
}) {
  return ref.read(loadDeckDeletionImpactUseCaseProvider).call(deckId);
}
