import 'package:memox_v6/domain/study_session/study_session.dart';

/// What tapping `Start review` resolved to
/// (`start-review-from-today.md` §2).
sealed class StartReviewOutcome {
  const StartReviewOutcome();
}

/// A session was already active. §1: "Nếu có paused Session, priority/choice
/// theo Session contract" — the schema allows exactly one active session, so
/// starting a second is not a choice the learner can be offered.
class ResumeActiveSession extends StartReviewOutcome {
  const ResumeActiveSession();
}

/// Nothing is due any more (flow node D). §4: "No longer due chuyển caught-up,
/// không báo lỗi" — a stale count is not a failure, it is old news.
class NothingDueNow extends StartReviewOutcome {
  const NothingDueNow();
}

/// A review session was committed and the learner should be handed to it.
class ReviewStarted extends StartReviewOutcome {
  const ReviewStarted(this.session);

  final StudySession session;
}

/// Due cards are spread over more than one deck, so the scope has to be
/// chosen before a session can exist.
///
/// Not a design preference: `study_sessions.deck_id` is `NOT NULL` with a
/// foreign key and `scope` is checked against `leaf`/`subtree`, so a
/// library-wide session cannot be represented in schema v1 at all. Narrowing
/// silently to one deck would start 15 cards under a button that says 24.
class ChooseReviewScope extends StartReviewOutcome {
  const ChooseReviewScope({required this.options});

  /// The decks that actually have something eligible, with the counts that
  /// make the choice meaningful. Carried rather than re-queried by the screen:
  /// the numbers the learner picks between must be the ones the revalidation
  /// just read, not a second answer from a moment later.
  final List<ReviewScopeOption> options;

  int get deckCount => options.length;
}

/// One deck the learner may scope the session to.
class ReviewScopeOption {
  const ReviewScopeOption({
    required this.deckId,
    required this.deckName,
    required this.eligibleCount,
  });

  final String deckId;
  final String deckName;

  /// Due cards for a review, unstudied cards for a new-learning start — the
  /// queue the chosen session type would run over.
  final int eligibleCount;
}
