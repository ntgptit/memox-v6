import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';
import 'package:memox_v6/domain/usecases/study_goal/set_daily_study_goal_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/track_daily_goal_usecase.dart';

/// WBS study-goal — `set-daily-study-goal.md`.
///
/// The producer for goal tracking. `TrackDailyGoalUseCase` and
/// `LoadDailyProgressUseCase` both start from `latestGoal()`, and nothing
/// could create one: `createGoal`/`updateGoal` had no caller anywhere, so the
/// tracking built for them was inert by construction.
class _Goals implements StudyGoalRepository {
  DailyGoal? goal;
  final Map<String, GoalDayProgress> buckets = <String, GoalDayProgress>{};
  int creates = 0;
  int updates = 0;

  @override
  Future<DailyGoal?> latestGoal() async => goal;

  @override
  Future<void> createGoal(DailyGoal goal) async {
    creates++;
    this.goal = goal;
  }

  @override
  Future<void> updateGoal(
    String goalId, {
    required bool isEnabled,
    required int targetCardCount,
    required DateTime updatedAt,
  }) async {
    updates++;
    final current = goal!;
    goal = DailyGoal(
      id: current.id,
      isEnabled: isEnabled,
      targetCardCount: targetCardCount,
      effectiveFromLocalDate: current.effectiveFromLocalDate,
      timezoneId: current.timezoneId,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<GoalDayProgress?> dayProgress(String localDate) async =>
      buckets[localDate];

  @override
  Future<void> recordDayProgress(GoalDayProgress progress) async {
    buckets[progress.localDate] = progress;
  }

  @override
  Stream<GoalDayProgress?> watchDayProgress(String localDate) =>
      Stream<GoalDayProgress?>.value(buckets[localDate]);
}

class _Ids implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'g${_next++}';
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

void main() {
  late _Goals goals;
  late SetDailyStudyGoalUseCase usecase;

  final now = DateTime.utc(2026, 7, 26, 3);
  const zone = FixedOffsetTimeZone(id: 'UTC+07', offset: Duration(hours: 7));

  setUp(() {
    goals = _Goals();
    usecase = SetDailyStudyGoalUseCase(
      goals: goals,
      timeZone: zone,
      clock: _FixedClock(now),
      idGenerator: _Ids(),
    );
  });

  test('the first save creates the configuration', () async {
    final goal = await usecase(isEnabled: true, targetCardCount: 20);

    expect(goals.creates, 1);
    expect(goal.isEnabled, isTrue);
    expect(goal.targetCardCount, 20);
    // Stamped in the user's zone, not UTC: the goal's day boundary follows
    // them, and 03:00Z is already the 26th at +07:00.
    expect(goal.effectiveFromLocalDate, '2026-07-26');
    expect(goal.timezoneId, 'UTC+07');
  });

  // §1: one effective configuration at a time.
  test('a later save updates the same row rather than stacking', () async {
    final first = await usecase(isEnabled: true, targetCardCount: 20);
    final second = await usecase(isEnabled: true, targetCardCount: 30);

    expect(goals.creates, 1);
    expect(goals.updates, 1);
    expect(second.id, first.id);
    expect(second.targetCardCount, 30);
  });

  // §1: re-targeting must not rewrite what earlier days were measured against.
  test('re-targeting keeps the original effective date and zone', () async {
    await usecase(isEnabled: true, targetCardCount: 20);
    final updated = await usecase(isEnabled: true, targetCardCount: 30);

    expect(updated.effectiveFromLocalDate, '2026-07-26');
    expect(updated.createdAt, now);
  });

  test('an enabled goal needs a positive target', () async {
    await expectLater(
      usecase(isEnabled: true, targetCardCount: 0),
      throwsA(isA<ValidationFailure>()),
    );
    await expectLater(
      usecase(isEnabled: true, targetCardCount: -5),
      throwsA(isA<ValidationFailure>()),
    );
    expect(goals.creates, 0, reason: 'invalid input writes nothing');
  });

  // §5: a disabled goal keeps its last target so re-enabling need not ask
  // again. The schema forbids a non-positive target either way.
  test('disabling keeps the target', () async {
    await usecase(isEnabled: true, targetCardCount: 20);
    final disabled = await usecase(isEnabled: false, targetCardCount: 20);

    expect(disabled.isEnabled, isFalse);
    expect(disabled.targetCardCount, 20);
  });

  // The whole point: tracking was inert until something could create a goal.
  test('tracking activates once a goal exists', () async {
    final track = TrackDailyGoalUseCase(
      goals: goals,
      timeZone: zone,
      idGenerator: _Ids(),
    );

    final before = await track(qualifiedCardCount: 6, finalizedAt: now);
    expect(before.isActive, isFalse, reason: 'no goal configured yet');

    await usecase(isEnabled: true, targetCardCount: 20);

    final after = await track(qualifiedCardCount: 6, finalizedAt: now);
    expect(after.isActive, isTrue);
    expect(after.currentAmount, 6);
    expect(after.target, 20);
  });
}
