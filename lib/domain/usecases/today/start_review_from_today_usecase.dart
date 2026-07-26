import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/start_review_outcome.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// Revalidates the dashboard's due projection and hands off to the study
/// session (WBS 5.7.3; `start-review-from-today.md`).
///
/// §1: "Due count trên Dashboard chỉ là projection; Start recompute
/// eligibility." The count on screen was composed when Today loaded and may be
/// minutes old — cards fall due, get answered elsewhere, or a session starts on
/// another surface. Every branch below is that recomputation, not a re-read of
/// what the screen already believed.
class StartReviewFromTodayUseCase {
  const StartReviewFromTodayUseCase({
    required StudySessionRepository sessions,
    required DeckRepository decks,
    required SelectLanguagePairUseCase languagePairs,
    required LoadStudyQueueCountsUseCase queueCounts,
    required StartStudySessionUseCase startSession,
  }) : _sessions = sessions,
       _decks = decks,
       _languagePairs = languagePairs,
       _queueCounts = queueCounts,
       _startSession = startSession;

  final StudySessionRepository _sessions;
  final DeckRepository _decks;
  final SelectLanguagePairUseCase _languagePairs;
  final LoadStudyQueueCountsUseCase _queueCounts;
  final StartStudySessionUseCase _startSession;

  /// [type] selects which queue is revalidated: `dueReview` for the primary
  /// CTA, `newLearning` for the caught-up state's optional action
  /// (`handle-caught-up-today.md` §2 node G, "Revalidate Study flow" — the
  /// same revalidation, over the queue that state is about).
  Future<StartReviewOutcome> call({
    SessionType type = SessionType.dueReview,
  }) async {
    // A → B: the active session is revalidated first, because it decides the
    // answer on its own — no count matters if one is already running.
    final active = await _sessions.watchActive().first;
    if (active != null) return const ResumeActiveSession();

    final pair = await _languagePairs.activePair();
    if (pair == null) return const NothingDueNow();

    // B → C: recomputed per root deck rather than read from the library
    // total, because the total cannot say *where* the cards are, and the
    // session that follows needs a scope. `forDeck` aggregates a Parent's
    // subtree, so an eligible card in a nested deck counts toward its root.
    final roots = await _decks.watchRoots(pair.id).first;
    final eligibleRoots = <String>[];
    for (final deck in roots) {
      final counts = await _queueCounts.forDeck(deck.id);
      final count = type == SessionType.newLearning
          ? counts.newCount
          : counts.dueCount;
      if (count > 0) eligibleRoots.add(deck.id);
    }

    if (eligibleRoots.isEmpty) return const NothingDueNow();
    if (eligibleRoots.length > 1) {
      return ChooseReviewScope(deckCount: eligibleRoots.length);
    }

    // C → E → F: one scope, so there is nothing to choose. The session is
    // created by the Start Session contract (§6) — this use case supplies the
    // scope it revalidated and nothing else.
    final session = await _startSession.call(
      deckId: eligibleRoots.single,
      scope: SessionScope.subtree,
      type: type,
    );
    return ReviewStarted(session);
  }
}
