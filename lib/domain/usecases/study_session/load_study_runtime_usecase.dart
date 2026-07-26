import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/study_session/session_mode_plan.dart';
import 'package:memox_v6/domain/study_session/study_eligibility_policy.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// The initial round index the start snapshot writes (5.6.2), used to find the
/// current order before any checkpoint exists.
const int _initialRoundIndex = 1;

/// Loads the active session's runtime read model (WBS 5.6.3;
/// `resume-study-session.md` §7). Presentation depends on this use case, never
/// the repository directly. It projects the committed snapshot + checkpoint +
/// current round order into a [StudyRuntimeState], or `null` when no session is
/// active.
///
/// `null` means exactly one thing: nothing to resume. A session that exists
/// but cannot be assembled raises instead, so the screen can offer the retry
/// §3's node H asks for rather than showing an empty state over committed
/// answers.
///
/// The mode plan is rebuilt from the **snapshot**, not from live data.
/// `SessionModePlan` is explicit that a snapshotted plan is "replayed verbatim
/// on Retry/Resume — never re-resolved (ST-TYPE-018)", and `study_sessions`
/// stores no plan id, so replaying it means recomputing the same inputs over
/// the frozen card snapshot: the Relearn plan branches on whether the pool had
/// five distinct meanings, and those meanings are in the snapshot rows.
///
/// This resolved with the default `guessPoolSufficient: false` until
/// 2026-07-27, on the strength of a comment saying relearn was not startable.
/// It became startable when the Study Result's `Review mistakes` was wired,
/// and from then on resuming a Guess relearn session silently handed the
/// learner the binary fallback instead — a different plan from the one their
/// session was started under.
class LoadStudyRuntimeUseCase {
  const LoadStudyRuntimeUseCase({
    required StudySessionRepository sessions,
    SessionModePlanResolver planResolver = const SessionModePlanResolver(),
    StudyEligibilityPolicy eligibility = const StudyEligibilityPolicy(),
  }) : _sessions = sessions,
       _planResolver = planResolver,
       _eligibility = eligibility;

  final StudySessionRepository _sessions;
  final SessionModePlanResolver _planResolver;

  /// The same policy the start use case asked, so the two cannot disagree
  /// about how large a Guess pool has to be.
  final StudyEligibilityPolicy _eligibility;

  Future<StudyRuntimeState?> call() async {
    // A point-in-time read: `watchActive().first` opens a query stream and
    // waits for an emission that lands a frame later.
    final session = await _sessions.activeSession();
    if (session == null) return null;

    final cardSnapshots = await _sessions.cardSnapshots(session.id);
    // Recomputed over the frozen rows, so it reproduces the decision start
    // made rather than asking today's library the same question.
    final distinctMeanings = cardSnapshots
        .map((snapshot) => StringUtils.comparisonKey(snapshot.meaning))
        .toSet()
        .length;
    final plan = _planResolver.resolve(
      type: session.type,
      guessPoolSufficient: _eligibility.isGuessPoolSufficient(distinctMeanings),
    );
    final checkpoint = await _sessions.checkpoint(session.id);
    final currentOrder = await _sessions.roundOrder(
      session.id,
      checkpoint?.roundIndex ?? _initialRoundIndex,
    );
    if (currentOrder == null) {
      // `resume-study-session.md` §3 separates node E ("Missing" — there is no
      // session) from node H (a recoverable error on a session that exists).
      // This returned null for both, so a session whose round order could not
      // be read rendered the empty "no session" state: the learner was told
      // they had nothing to resume while their answers sat committed in the
      // store, and the screen offered no way to try again.
      throw DataCorruptionFailure(
        entity: 'study_round_orders',
        field: 'roundIndex',
        value: '${checkpoint?.roundIndex ?? _initialRoundIndex}',
      );
    }

    return StudyRuntimeState.assemble(
      session: session,
      stages: plan.stages,
      cardSnapshots: cardSnapshots,
      currentOrder: currentOrder,
      checkpoint: checkpoint,
    );
  }
}
