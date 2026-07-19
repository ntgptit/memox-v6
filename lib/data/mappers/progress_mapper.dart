import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/mappers/primitive_mapper.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/preferences/preference_entry.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';

/// Progress/rhythm row → domain mappers (WBS 4.5).

extension LearningProgressRowMapper on db.LearningProgressData {
  LearningProgress toDomain() => LearningProgress(
    id: id,
    cardId: cardId,
    box: box,
    dueAt: utcDateTimeOrNull(dueAt),
    policyId: policyId,
    policyVersion: policyVersion,
    revision: revision,
    repetitionCount: repetitionCount,
    lapseCount: lapseCount,
    lastTerminalAttemptId: lastTerminalAttemptId,
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension PreferenceRowMapper on db.Preference {
  /// Decodes the versioned JSON payload. Invalid payloads return null —
  /// the reader falls back to its default instead of receiving garbage
  /// (the schema-v1 "invalid fallback" contract).
  PreferenceEntry? toDomainOrNull() {
    final decoded = tryDecodeJson(valueJson);
    if (decoded == null) return null;
    return PreferenceEntry(
      key: prefKey,
      value: decoded,
      schemaVersion: valueSchemaVersion,
      updatedAt: utcDateTime(updatedAt),
    );
  }
}

extension DailyGoalRowMapper on db.DailyGoal {
  DailyGoal toDomain() => DailyGoal(
    id: id,
    isEnabled: storedBool(
      isEnabled,
      entity: 'daily_goals',
      field: 'is_enabled',
    ),
    targetCardCount: targetCardCount,
    effectiveFromLocalDate: effectiveFromLocalDate,
    timezoneId: timezoneId,
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension GoalDayProgressRowMapper on db.GoalDayProgressData {
  GoalDayProgress toDomain() => GoalDayProgress(
    id: id,
    localDate: localDate,
    timezoneId: timezoneId,
    goalId: goalId,
    qualifiedCardCount: qualifiedCardCount,
    targetSnapshot: targetSnapshot,
    isMet: storedBool(isMet, entity: 'goal_day_progress', field: 'is_met'),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension StreakDayRowMapper on db.StreakDay {
  StreakDay toDomain() => StreakDay(
    id: id,
    localDate: localDate,
    timezoneId: timezoneId,
    qualifiedSource: qualifiedSource,
    sourceVersion: sourceVersion,
  );
}
