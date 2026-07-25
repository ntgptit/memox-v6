import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';
import 'package:memox_v6/domain/flashcard/edit_flashcard_result.dart';
import 'package:memox_v6/domain/usecases/flashcard/edit_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/open_deck_usecase.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';

/// Dependency preconditions for kit visual-parity states (WBS P0.3).
///
/// The companion of `data/dev/parity_fixtures.dart`: that file seeds
/// rows, this one supplies the provider overrides a state needs. They
/// are split because providers are wired in the app layer and the data
/// layer must not reach into it.
///
/// Some states exist only when an operation fails. Making the failure a
/// precondition — a write path broken *before* the user acts — is not a
/// shortcut: the spec still walks the whole flow and presses the real
/// control, and what renders afterwards is the production error path.
/// Seeding the rendered error instead would hide exactly the wiring this
/// gate exists to check.
List<Override> parityOverridesFor(String fixtureId) {
  return switch (fixtureId) {
    'MX-VIS-011' => <Override>[
      createDeckUseCaseProvider.overrideWith(
        (ref) => _HangingCreateDeckUseCase(
          decks: ref.watch(deckRepositoryProvider),
          pairs: ref.watch(languagePairRepositoryProvider),
          idGenerator: ref.watch(idGeneratorProvider),
          clock: ref.watch(appClockProvider),
        ),
      ),
    ],
    'MX-VIS-012' => <Override>[
      createDeckUseCaseProvider.overrideWith(
        (ref) => _FailingCreateDeckUseCase(
          decks: ref.watch(deckRepositoryProvider),
          pairs: ref.watch(languagePairRepositoryProvider),
          idGenerator: ref.watch(idGeneratorProvider),
          clock: ref.watch(appClockProvider),
        ),
      ),
    ],
    // The Card Editor's two in-flight/failed save states, the same shape as
    // MX-VIS-011/012 one layer up: the deck and the card both reach the
    // editor through the real journey, and only the final write is pinned.
    'MX-VIS-056' => <Override>[
      createFlashcardUseCaseProvider.overrideWith(
        (ref) => _HangingCreateFlashcardUseCase(
          cards: ref.watch(flashcardRepositoryProvider),
          decks: ref.watch(deckRepositoryProvider),
          idGenerator: ref.watch(idGeneratorProvider),
          clock: ref.watch(appClockProvider),
        ),
      ),
    ],
    // Submit-error is measured against the kit's *edit* shot — its app bar
    // reads "Edit card", because the kit gives "New card" only to the create
    // view — so the failing path here is the edit write, not the create one.
    'MX-VIS-057' => <Override>[
      editFlashcardUseCaseProvider.overrideWith(
        (ref) => _FailingEditFlashcardUseCase(
          cards: ref.watch(flashcardRepositoryProvider),
          decks: ref.watch(deckRepositoryProvider),
          clock: ref.watch(appClockProvider),
        ),
      ),
    ],
    // The two deck-detail loading states. Only the card stream is pinned:
    // the child-deck stream still resolves, which is what lets the screen
    // derive Parent vs Leaf and pick the matching kit composition. Pinning
    // both would collapse them into one indistinguishable state.
    'MX-VIS-037' || 'MX-VIS-043' => <Override>[
      openDeckUseCaseProvider.overrideWith(
        (ref) => _PendingCardsOpenDeckUseCase(
          decks: ref.watch(deckRepositoryProvider),
          cards: ref.watch(flashcardRepositoryProvider),
        ),
      ),
    ],
    // Study Result standard: a finished session's committed summary. The result
    // is a terminal screen whose precondition (a completed, finalized session)
    // is not an active row a data fixture could resume into, so the summary is
    // supplied directly here; the finalize orchestration is unit-tested.
    'MX-VIS-054' => <Override>[
      studyResultProvider.overrideWith(_SeededStudyResult.new),
    ],
    _ => const <Override>[],
  };
}

/// Renders the Study Result standard state with the kit's committed summary
/// (24 reviewed, 21 correct → 88%, 6:30 active, a 12-day streak at 14/20 min).
class _SeededStudyResult extends StudyResult {
  @override
  AsyncValue<StudySessionSummary?> build() =>
      const AsyncData<StudySessionSummary?>(
        StudySessionSummary(
          reviewedCount: 24,
          correctCount: 21,
          missedCardIds: <String>['m1', 'm2', 'm3'],
          durationActiveMs: 390000,
          goalStatus: StudyResultGoalStatus(
            streakDays: 12,
            goalDoneMinutes: 14,
            goalTargetMinutes: 20,
          ),
        ),
      );
}

/// A deck read whose card stream never emits, for the two loading states.
///
/// Same contract as the hanging create path below: an in-flight state is
/// pinned so the capture is a still frame rather than a race against the
/// real read finishing. `childrenOf` is deliberately left alone —
/// `subdeck-list--loading` and `flashcard-list--loading` are different
/// kit compositions, and the screen tells them apart by whether the deck
/// resolved any child decks.
class _PendingCardsOpenDeckUseCase extends OpenDeckUseCase {
  const _PendingCardsOpenDeckUseCase({
    required super.decks,
    required super.cards,
  });

  @override
  Stream<List<Flashcard>> cardsOf(String deckId) =>
      StreamController<List<Flashcard>>().stream;
}

/// A card write that never completes, for `flashcard-editor--submitting`.
///
/// The editor freezes its fields and swaps Save for "Saving…" while the
/// command is in flight, so pinning the command is what holds that frame
/// still — the alternative is racing a real write that finishes in
/// milliseconds.
class _HangingCreateFlashcardUseCase extends CreateFlashcardUseCase {
  const _HangingCreateFlashcardUseCase({
    required super.cards,
    required super.decks,
    required super.idGenerator,
    required super.clock,
  });

  @override
  Future<CreateFlashcardResult> call({
    required String deckId,
    required String term,
    required String primaryMeaning,
    String? retryCardId,
    bool allowDuplicate = false,
    List<({String languageCode, String text})> translations = const [],
    List<String> tagIds = const [],
    List<CardAudioRef> audioRefs = const [],
  }) {
    return Completer<CreateFlashcardResult>().future;
  }
}

/// An edit that always fails, for `flashcard-editor--submit-error`.
///
/// The kit draws this state in the edit variant, so the journey opens an
/// existing card rather than a blank form. It throws instead of returning a
/// typed result, so the edited draft stays intact behind the failure banner —
/// which is the point of the state: `edit-flashcard.md` requires the user's
/// changes to survive a failed save.
class _FailingEditFlashcardUseCase extends EditFlashcardUseCase {
  const _FailingEditFlashcardUseCase({
    required super.cards,
    required super.decks,
    required super.clock,
  });

  @override
  Future<EditFlashcardResult> call({
    required String cardId,
    required String term,
    required String primaryMeaning,
    required int expectedContentVersion,
    bool allowDuplicate = false,
  }) async {
    throw const UnexpectedFailure(
      cause: 'parity fixture: the card edit path fails for MX-VIS-057',
    );
  }
}

/// A create path that never completes, for the submitting state.
///
/// The P0.3 fixture contract asks in-flight states to pin the command on
/// a completer nothing ever resolves, so the capture is a still frame
/// rather than a race against the real write finishing.
class _HangingCreateDeckUseCase extends CreateDeckUseCase {
  const _HangingCreateDeckUseCase({
    required super.decks,
    required super.pairs,
    required super.idGenerator,
    required super.clock,
  });

  @override
  Future<Deck> call({
    required String name,
    required String languagePairId,
    String? parentId,
    String? retryDeckId,
    String? description,
  }) {
    return Completer<Deck>().future;
  }
}

/// A create path that always fails, for the submit-failure state.
///
/// It throws instead of validating, so the draft stays intact and the
/// banner — not a field error — is what renders, matching
/// `create-deck-firstrun--submit-failure`.
class _FailingCreateDeckUseCase extends CreateDeckUseCase {
  const _FailingCreateDeckUseCase({
    required super.decks,
    required super.pairs,
    required super.idGenerator,
    required super.clock,
  });

  @override
  Future<Deck> call({
    required String name,
    required String languagePairId,
    String? parentId,
    String? retryDeckId,
    String? description,
  }) async {
    throw const UnexpectedFailure(
      cause: 'parity fixture: the deck write path fails for MX-VIS-012',
    );
  }
}
