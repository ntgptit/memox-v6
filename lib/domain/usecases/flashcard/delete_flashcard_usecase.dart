import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/flashcard/delete_card_impact.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';

/// Deletes a card (WBS 5.3.1C; `delete-flashcard.md`). The explicit
/// confirmation lives in the UI; this command removes child content
/// and current scheduling state and tombstones the card in one
/// transaction. Finalized session summaries are never rewritten, and
/// the last card leaving a deck turns it Leaf → Empty by derivation.
class DeleteFlashcardUseCase {
  const DeleteFlashcardUseCase({
    required FlashcardRepository cards,
    required LoadStudyRuntimeUseCase runtime,
    required AppClock clock,
  }) : _cards = cards,
       _runtime = runtime,
       _clock = clock;

  final FlashcardRepository _cards;
  final LoadStudyRuntimeUseCase _runtime;
  final AppClock _clock;

  /// What a delete would disturb, for the confirm to state (§3's "Load
  /// content/session/progress impact", §9's "Confirm states exact impact").
  ///
  /// It raises for the same reason [deleteCard] does when the runtime cannot
  /// be assembled: that is precisely the case where nobody can say whether
  /// this card is the one on screen.
  Future<DeleteCardImpact> impactOf(String cardId) async {
    final runtime = await _runtime();
    if (runtime == null) return DeleteCardImpact.none;
    if (runtime.position.currentCardId == cardId) {
      return DeleteCardImpact.currentPrompt;
    }
    if (runtime.cardsById.containsKey(cardId)) {
      return DeleteCardImpact.inSession;
    }
    return DeleteCardImpact.none;
  }

  Future<void> deleteCard(String cardId) async {
    final card = await _cards.findById(cardId);
    if (card == null) {
      throw ValidationFailure(field: 'cardId', code: 'not-found');
    }
    if (card.isDeleted) return;
    await _refuseIfCurrentPrompt(cardId);
    await _cards.deleteCardCascade(cardId, now: _clock.nowUtc());
  }

  /// ST-CHG-007 / §5: "Current prompt hoặc pending answer | Block delete".
  ///
  /// A card further down the queue may go — §5 allows that, and the session
  /// skips it when its turn comes. The one the learner is answering right now
  /// may not: deleting it would take the prompt out from under them mid-answer.
  ///
  /// A session whose runtime cannot be assembled raises rather than resolving
  /// to "no current prompt". That is exactly the case where nobody can say
  /// whether this card is the one on screen, and a delete that cannot be shown
  /// to be safe is not one to wave through.
  Future<void> _refuseIfCurrentPrompt(String cardId) async {
    final runtime = await _runtime();
    if (runtime == null) return;
    if (runtime.position.currentCardId != cardId) return;
    throw ConflictFailure(code: 'card-in-session', entity: 'flashcards');
  }
}
