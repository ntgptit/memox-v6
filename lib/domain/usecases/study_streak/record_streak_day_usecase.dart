import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';

/// Outcome of offering a finalized session to the streak.
enum RecordStreakDayResult {
  /// The day was newly marked qualified.
  recorded,

  /// The day was already qualified — a repeat session, a retry or a resync.
  /// Success, not an error (`record-streak-day.md` §2 "idempotent success").
  alreadyQualified,

  /// The session does not qualify: Practice, or no card reached a terminal
  /// outcome. Nothing is written.
  notQualifying,
}

/// Marks the local day a finalized session contributed to
/// (`record-streak-day.md`).
///
/// Qualification is `metrics-v1`, not this file's invention:
/// - `qualifyingSession` — a finalized `newLearning`, `dueReview` or `relearn`
///   session. Practice "does not contribute Goal/Streak in v1".
/// - "A streak day qualifies when at least one qualifying session finalizes
///   with at least one qualified Card."
///
/// Independent of the daily goal by contract (§6: "Không phụ thuộc Daily Goal
/// enabled/met") — a day qualifies on activity, whether or not a target was
/// set or reached.
class RecordStreakDayUseCase {
  const RecordStreakDayUseCase({
    required StreakRepository streaks,
    required AppTimeZone timeZone,
    required IdGenerator idGenerator,
  }) : _streaks = streaks,
       _timeZone = timeZone,
       _idGenerator = idGenerator;

  final StreakRepository _streaks;
  final AppTimeZone _timeZone;
  final IdGenerator _idGenerator;

  /// Records the day [finalizedAt] falls in, when the session qualifies.
  ///
  /// [qualifiedCardCount] is the count of distinct cards that reached a
  /// terminal outcome — `StudySessionSummary.reviewedCount`. Zero means the
  /// session finalized without anyone actually answering anything, which is
  /// not a day's study however long it was open.
  Future<RecordStreakDayResult> call({
    required String sessionId,
    required SessionType sessionType,
    required int qualifiedCardCount,
    required DateTime finalizedAt,
  }) async {
    // Fail closed: an event that does not qualify creates no day (§4).
    if (!_qualifies(sessionType) || qualifiedCardCount <= 0) {
      return RecordStreakDayResult.notQualifying;
    }

    // The day is resolved from the instant through the zone, never from the
    // UTC date (§1: "Identity ngày là calendar date trong timezone contract,
    // không phải UTC date thuần"). A session finished at 23:30+07:00 belongs
    // to that local day, not to the UTC day before it.
    final localDay = _timeZone.localDayOf(finalizedAt);
    final localDate = localDay.toString();

    final existing = await _streaks.daysBetween(localDate, localDate);
    if (existing.isNotEmpty) {
      // Already qualified — by an earlier session today, or by this same event
      // arriving twice. Either way the contribution is already counted, and
      // reporting success is what makes a retry safe (§6: "cùng event/day
      // retry trả kết quả cũ").
      return RecordStreakDayResult.alreadyQualified;
    }

    await _streaks.recordDay(
      StreakDay(
        id: _idGenerator.newId(),
        localDate: localDate,
        timezoneId: _timeZone.id,
        // The source event, kept for audit and dedupe. It never gates the
        // write: a *second* session on an already-qualified day is a
        // legitimate no-op, not a duplicate to reject.
        qualifiedSource: sessionId,
        sourceVersion: sourceVersion,
      ),
      recordedAt: finalizedAt,
    );
    return RecordStreakDayResult.recorded;
  }

  /// Policy version stamped on each record, so a rule change can be told from
  /// history written under the old one (§3).
  static const int sourceVersion = 1;

  bool _qualifies(SessionType type) => switch (type) {
    SessionType.newLearning ||
    SessionType.dueReview ||
    SessionType.relearn => true,
    SessionType.practice => false,
  };
}
