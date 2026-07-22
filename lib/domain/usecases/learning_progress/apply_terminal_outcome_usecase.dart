import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';

/// Applies a terminal study outcome to a card's SRS progress as one atomic,
/// exactly-once operation (WBS 5.4.4; SRS Policy v1 §§3,5–8; SRS8-001,
/// 003–012, 017–024, 028). The atomic Attempt+Progress write itself lives in
/// the data layer; this use case only decides the next state.
///
/// It reads the card's current progress, validates its policy id (SRS8-028),
/// computes the next box/due with the pure [Srs8BoxPolicy], derives counters
/// (§8: a terminal grade increments repetitions, a `wrong` grade also
/// increments lapses; activation leaves counters untouched), then persists the
/// evidence and the new schedule through
/// [LearningProgressRepository.applyScheduledOutcome] — whose idempotency key
/// makes a replay a no-op (SRS8-011) and whose guarded revision raises a typed
/// [ConflictFailure] on a concurrent write (SRS8-012). This use case computes
/// no schedule itself; the box, due date and counters always arrive from the
/// policy.
class ApplyTerminalOutcomeUseCase {
  const ApplyTerminalOutcomeUseCase({
    required LearningProgressRepository repository,
    Srs8BoxPolicy policy = const Srs8BoxPolicy(),
  }) : _repository = repository,
       _policy = policy;

  final LearningProgressRepository _repository;
  final Srs8BoxPolicy _policy;

  /// Activate a completed new card: Box 0 → Box 1 (SRS8-001). Counters are
  /// untouched — activation is not a graded repetition (§3 activation result).
  Future<void> activate({
    required StudyAttempt attempt,
    required DateTime nowUtc,
  }) async {
    final current = await _load(attempt.cardId);
    if (current.box != Srs8BoxPolicy.newBox) {
      throw ValidationFailure(field: 'box', code: 'already-activated');
    }
    final decision = _policy.activate(nowUtc: nowUtc);
    await _persist(
      current,
      attempt,
      decision,
      nowUtc,
      repetitionCount: current.repetitionCount,
      lapseCount: current.lapseCount,
    );
  }

  /// Apply a binary terminal grade to an activated card in Box 1..8
  /// (SRS8-003–009, 017–024). Repetitions always increment; a `wrong` grade
  /// also increments lapses (§8).
  Future<void> applyGrade({
    required StudyAttempt attempt,
    required SrsGrade grade,
    required DateTime nowUtc,
  }) async {
    final current = await _load(attempt.cardId);
    if (current.box == Srs8BoxPolicy.newBox) {
      throw ValidationFailure(field: 'box', code: 'not-activated');
    }
    final decision = _policy.applyGrade(
      currentBox: current.box,
      grade: grade,
      nowUtc: nowUtc,
    );
    await _persist(
      current,
      attempt,
      decision,
      nowUtc,
      repetitionCount: current.repetitionCount + 1,
      lapseCount: current.lapseCount + (grade == SrsGrade.wrong ? 1 : 0),
    );
  }

  Future<LearningProgress> _load(String cardId) async {
    final current = await _repository.findByCard(cardId);
    if (current == null) {
      throw ValidationFailure(field: 'cardId', code: 'no-progress');
    }
    if (current.policyId != Srs8BoxPolicy.policyId) {
      throw ValidationFailure(field: 'policyId', code: 'unknown');
    }
    return current;
  }

  Future<void> _persist(
    LearningProgress current,
    StudyAttempt attempt,
    SrsScheduleDecision decision,
    DateTime nowUtc, {
    required int repetitionCount,
    required int lapseCount,
  }) {
    return _repository.applyScheduledOutcome(
      attempt: attempt,
      newBox: decision.box,
      newDueAt: decision.dueAt,
      repetitionCount: repetitionCount,
      lapseCount: lapseCount,
      expectedRevision: current.revision,
      updatedAt: nowUtc,
    );
  }
}
