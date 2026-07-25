import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';
import 'package:memox_v6/domain/usecases/study_goal/load_daily_progress_usecase.dart';

/// The cold read of today's streak + goal, for Today's Daily-goal card.
///
/// The Study Result builds the same numbers from the session it just
/// finalized; both go through the same projection over the same day records,
/// which is the point — nothing caches a running total that could disagree.
class _Streaks implements StreakRepository {
  _Streaks(List<String> dates)
    : days = <StreakDay>[
        for (final date in dates)
          StreakDay(
            id: date,
            localDate: date,
            timezoneId: 'UTC',
            qualifiedSource: 'seed',
            sourceVersion: 1,
          ),
      ];

  final List<StreakDay> days;

  @override
  Future<void> recordDay(StreakDay day, {required DateTime recordedAt}) async {
    days.add(day);
  }

  @override
  Future<List<StreakDay>> daysBetween(String from, String to) async => days
      .where(
        (d) =>
            d.localDate.compareTo(from) >= 0 && d.localDate.compareTo(to) <= 0,
      )
      .toList();

  @override
  Future<int> countDays() async => days.length;
}

class _Goals implements StudyGoalRepository {
  _Goals({this.goal, this.bucket});

  DailyGoal? goal;
  GoalDayProgress? bucket;

  @override
  Future<DailyGoal?> latestGoal() async => goal;

  @override
  Future<GoalDayProgress?> dayProgress(String localDate) async =>
      bucket?.localDate == localDate ? bucket : null;

  @override
  Future<void> recordDayProgress(GoalDayProgress progress) async =>
      bucket = progress;

  @override
  Stream<GoalDayProgress?> watchDayProgress(String localDate) =>
      Stream<GoalDayProgress?>.value(bucket);

  @override
  Future<void> createGoal(DailyGoal goal) async => this.goal = goal;

  @override
  Future<void> updateGoal(
    String goalId, {
    required bool isEnabled,
    required int targetCardCount,
    required DateTime updatedAt,
  }) async {}
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

void main() {
  final now = DateTime.utc(2026, 7, 26, 3);
  const zone = FixedOffsetTimeZone(id: 'UTC+07', offset: Duration(hours: 7));

  DailyGoal goalOf({int target = 20, bool enabled = true}) => DailyGoal(
    id: 'g1',
    isEnabled: enabled,
    targetCardCount: target,
    effectiveFromLocalDate: '2026-07-01',
    timezoneId: 'UTC+07',
    createdAt: now,
    updatedAt: now,
  );

  LoadDailyProgressUseCase build(_Streaks streaks, _Goals goals) =>
      LoadDailyProgressUseCase(
        streaks: streaks,
        goals: goals,
        timeZone: zone,
        clock: _FixedClock(now),
      );

  test('reports the streak and today\'s progress', () async {
    final status = await build(
      _Streaks(<String>['2026-07-24', '2026-07-25', '2026-07-26']),
      _Goals(
        goal: goalOf(),
        bucket: GoalDayProgress(
          id: 'b1',
          localDate: '2026-07-26',
          timezoneId: 'UTC+07',
          goalId: 'g1',
          qualifiedCardCount: 14,
          targetSnapshot: 20,
          isMet: false,
          updatedAt: now,
        ),
      ),
    )();

    expect(status.streakDays, 3);
    expect(status.goalDoneCards, 14);
    expect(status.goalTargetCards, 20);
    expect(status.hasGoal, isTrue);
    expect(status.isMet, isFalse);
  });

  // Before the day's first session there is no bucket. That is zero progress
  // against the configured target, not "no goal" — the card still shows.
  test('a day with no session yet reads zero against the target', () async {
    final status = await build(
      _Streaks(<String>['2026-07-25']),
      _Goals(goal: goalOf()),
    )();

    expect(status.goalDoneCards, 0);
    expect(status.goalTargetCards, 20);
    expect(status.hasGoal, isTrue);
    // Yesterday still counts, so the streak is live before today's session.
    expect(status.streakDays, 1);
  });

  test('no goal configured means no card', () async {
    final status = await build(_Streaks(<String>['2026-07-26']), _Goals())();

    expect(status.hasGoal, isFalse);
    expect(status.streakDays, 0);
  });

  test('a disabled goal means no card', () async {
    final status = await build(
      _Streaks(<String>['2026-07-26']),
      _Goals(goal: goalOf(enabled: false)),
    )();

    expect(status.hasGoal, isFalse);
  });

  test('a met day reports met', () async {
    final status = await build(
      _Streaks(<String>['2026-07-26']),
      _Goals(
        goal: goalOf(),
        bucket: GoalDayProgress(
          id: 'b1',
          localDate: '2026-07-26',
          timezoneId: 'UTC+07',
          goalId: 'g1',
          qualifiedCardCount: 22,
          targetSnapshot: 20,
          isMet: true,
          updatedAt: now,
        ),
      ),
    )();

    expect(status.isMet, isTrue);
  });

  // A row `reconcile-streak-history.md` owns repairing must not take the card
  // down with it.
  test('a malformed stored date is skipped, not fatal', () async {
    final status = await build(
      _Streaks(<String>['2026-07-25', 'not-a-date', '2026-07-26']),
      _Goals(goal: goalOf()),
    )();

    expect(status.streakDays, 2);
  });
}
