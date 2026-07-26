import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_snapshot_builder.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_eligibility_policy.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// Starts one study session for a deck scope (WBS 5.6.2; `start-study-session.md`).
///
/// It recomputes the eligible cards, checks start eligibility, then hands a
/// stable snapshot to the atomic `startSession` op (which enforces
/// exactly-one-active). A blocked start raises a typed [ValidationFailure]
/// whose `code` is the [StartBlockReason]. Only `newLearning` (new cards) and
/// `dueReview` (due cards) are wired here: `practice`'s "eligible scope" card
/// set (study-deck.md §85) needs a scope-wide active-card query, and `relearn`
/// needs a finalized session's missed set (5.6.13) — both raise
/// `unsupported-session-type` until their source exists.
class StartStudySessionUseCase {
  const StartStudySessionUseCase({
    required LearningProgressRepository progress,
    required FlashcardRepository cards,
    required StudySessionRepository sessions,
    required AppClock clock,
    required IdGenerator idGenerator,
    StudyEligibilityPolicy eligibility = const StudyEligibilityPolicy(),
  }) : _progress = progress,
       _cards = cards,
       _sessions = sessions,
       _clock = clock,
       _idGenerator = idGenerator,
       _eligibility = eligibility;

  final LearningProgressRepository _progress;
  final FlashcardRepository _cards;
  final StudySessionRepository _sessions;
  final AppClock _clock;
  final IdGenerator _idGenerator;
  final StudyEligibilityPolicy _eligibility;

  Future<StudySession> call({
    required String deckId,
    required SessionScope scope,
    required SessionType type,
    StudyModeType? selectedMode,
    List<String> relearnCardIds = const <String>[],
  }) async {
    // §3 node C, "Active session?". This used to be left to the partial
    // unique index on `state = 'active'`, so a caller starting a second
    // session got a raw constraint violation from the store rather than the
    // decision §1 requires — "Nếu có active session tương thích, user chọn
    // Resume hoặc Start over; không ghi đè im lặng". A constraint can stop
    // the write; it cannot tell anyone what to do instead.
    final active = await _sessions.activeSession();
    if (active != null) {
      throw ConflictFailure(code: 'active-session', entity: 'study_sessions');
    }

    final now = _clock.nowUtc();
    final candidates = await _progress.studyCandidatesInScope(
      scopeDeckId: deckId,
      nowUtc: now,
    );

    final cardIds = _cardIdsFor(
      type,
      candidates.newCardIds,
      candidates.dueCardIds,
      relearnCardIds,
    );
    final eligibleCards = await _resolveEligibleCards(cardIds);
    final distinctMeanings = eligibleCards
        .map((card) => StringUtils.comparisonKey(card.meaning))
        .toSet()
        .length;

    final eligibility = _eligibility.resolve(
      type: type,
      selectedMode: selectedMode,
      eligibleCardCount: eligibleCards.length,
      dueCardCount: candidates.dueCount,
      distinctMeaningCount: distinctMeanings,
    );
    final blockReason = eligibility.blockReason;
    if (blockReason != null) {
      throw ValidationFailure(field: 'start', code: blockReason.name);
    }

    final sessionId = _idGenerator.newId();
    final builder = SessionSnapshotBuilder(idGenerator: _idGenerator);
    final snapshot = builder.build(
      sessionId: sessionId,
      deckId: deckId,
      scope: scope,
      type: type,
      eligibleCards: eligibleCards,
      initialRoundIndex: 1,
      nowUtc: now,
      selectedMode: selectedMode,
      guessPoolSufficient: _eligibility.isGuessPoolSufficient(distinctMeanings),
    );

    await _sessions.startSession(
      session: snapshot.session,
      cardSnapshots: snapshot.cardSnapshots,
      initialOrder: snapshot.initialOrder,
    );
    return snapshot.session;
  }

  List<String> _cardIdsFor(
    SessionType type,
    List<String> newCardIds,
    List<String> dueCardIds,
    List<String> relearnCardIds,
  ) {
    if (type == SessionType.newLearning) return newCardIds;
    if (type == SessionType.dueReview) return dueCardIds;
    // Relearn does not select from the scope's queues: its queue is the
    // committed terminal-wrong set of a finalized session, handed in by the
    // caller (`relearn-cards.md` §1 — "Relearn queue được tạo từ terminal
    // outcomes đã commit của một session đã finalize"). Selecting by scope
    // here would sweep in cards the source session never got wrong.
    if (type == SessionType.relearn) {
      if (relearnCardIds.isEmpty) {
        throw ValidationFailure(field: 'relearnCardIds', code: 'required');
      }
      // Deduplicated in order: §1 caps a card at one queue position, and a
      // retried start must not double it.
      return <String>[
        ...<String>{...relearnCardIds},
      ];
    }
    throw ValidationFailure(
      field: 'sessionType',
      code: 'unsupported-session-type',
    );
  }

  Future<List<EligibleCard>> _resolveEligibleCards(List<String> cardIds) async {
    final resolved = <EligibleCard>[];
    for (final cardId in cardIds) {
      final card = await _cards.findById(cardId);
      final progress = await _progress.findByCard(cardId);
      // A card that vanished between the scope query and now is skipped, not
      // faked (start-study-session.md §1 hidden/deleted excluded before snapshot).
      if (card == null || progress == null) continue;
      resolved.add(
        EligibleCard(
          cardId: cardId,
          term: card.term,
          meaning: card.primaryMeaning,
          contentVersion: card.contentVersion,
          progressBox: progress.box,
          progressRevision: progress.revision,
        ),
      );
    }
    return resolved;
  }
}
