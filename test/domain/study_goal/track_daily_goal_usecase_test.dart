import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/daily_goal_contribution.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';
import 'package:memox_v6/domain/usecases/study_goal/track_daily_goal_usecase.dart';

/// WBS study-goal — `track-daily-goal.md` + the crossing that
/// `complete-daily-goal.md` consumes.
///
/// The unit under test is qualified **Cards**: `metrics-v1` fixes it and the
/// schema stores `target_card_count`. The kit's study-result shot reads
/// "14/20 min", but `StreakGoalCard.d.ts` records those numbers as hardcoded
/// samples that Flutter parameterizes.
class _FakeGoals implements StudyGoalRepository {
  _FakeGoals({this.goal});

  DailyGoal? goal;
  final Map<String, GoalDayProgress> buckets = <String, GoalDayProgress>{};

  @override
  Future<DailyGoal?> latestGoal() async => goal;

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

class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

void main() {
  late _FakeGoals goals;
  late TrackDailyGoalUseCase usecase;

  const zone = FixedOffsetTimeZone(id: 'UTC+07', offset: Duration(hours: 7));
  final at = DateTime.utc(2026, 7, 26, 3);

  DailyGoal goalOf({int target = 20, bool enabled = true}) => DailyGoal(
    id: 'g1',
    isEnabled: enabled,
    targetCardCount: target,
    effectiveFromLocalDate: '2026-07-01',
    timezoneId: 'UTC+07',
    createdAt: at,
    updatedAt: at,
  );

  setUp(() {
    goals = _FakeGoals(goal: goalOf());
    usecase = TrackDailyGoalUseCase(
      goals: goals,
      timeZone: zone,
      idGenerator: _SequentialIds(),
    );
  });

  Future<DailyGoalContribution> track(int cards, {DateTime? when}) =>
      usecase(qualifiedCardCount: cards, finalizedAt: when ?? at);

  test('the first session of the day opens the bucket', () async {
    final result = await track(6);

    expect(result.previousAmount, 0);
    expect(result.currentAmount, 6);
    expect(result.target, 20);
    expect(result.isMet, isFalse);
    expect(goals.buckets['2026-07-26']!.qualifiedCardCount, 6);
  });

  test('later sessions the same day accumulate', () async {
    await track(6);
    final result = await track(9);

    expect(result.previousAmount, 6);
    expect(result.currentAmount, 15);
  });

  test('crossing the target reports the transition exactly once', () async {
    await track(14);
    final crossing = await track(6);

    expect(crossing.isMet, isTrue);
    expect(crossing.crossedTarget, isTrue);

    // §1: "Một local day/config lineage phát tối đa một completion event."
    final after = await track(3);
    expect(after.isMet, isTrue);
    expect(after.crossedTarget, isFalse, reason: 'no second celebration');
  });

  test('over-target keeps accumulating and stays met', () async {
    await track(25);
    final result = await track(5);

    expect(result.currentAmount, 30);
    expect(result.isMet, isTrue);
  });

  test('a disabled goal counts no attainment', () async {
    goals.goal = goalOf(enabled: false);
    final result = await track(6);

    expect(result.isActive, isFalse);
    expect(result.crossedTarget, isFalse);
    expect(goals.buckets, isEmpty, reason: 'no bucket, no attainment');
  });

  test('no configured goal is inactive rather than an error', () async {
    goals.goal = null;

    expect((await track(6)).isActive, isFalse);
  });

  // `handle-goal-day-boundary.md`: the day is measured against the target that
  // was in force, so raising the goal mid-day cannot un-meet a met day.
  test('the day keeps the target it was opened with', () async {
    await track(20);
    goals.goal = goalOf(target: 50);
    final result = await track(1);

    expect(result.target, 20);
    expect(result.isMet, isTrue);
  });

  test('a day already met stays met even if the target is raised', () async {
    await track(20);
    expect(goals.buckets['2026-07-26']!.isMet, isTrue);

    goals.goal = goalOf(target: 100);
    final result = await track(0);

    expect(result.isMet, isTrue, reason: 'a met day is never un-met');
  });

  // §1: identity is the local day, so two sessions either side of local
  // midnight land in different buckets.
  test('sessions either side of local midnight fill separate days', () async {
    // 16:00 UTC = 23:00 local on the 26th; 18:00 UTC = 01:00 on the 27th.
    await track(4, when: DateTime.utc(2026, 7, 26, 16));
    await track(5, when: DateTime.utc(2026, 7, 26, 18));

    expect(goals.buckets['2026-07-26']!.qualifiedCardCount, 4);
    expect(goals.buckets['2026-07-27']!.qualifiedCardCount, 5);
  });

  test('the current value never goes negative', () async {
    final result = await track(-5);

    expect(result.currentAmount, 0);
  });

  test('the bucket snapshots the goal and zone that produced it', () async {
    await track(6);
    final bucket = goals.buckets['2026-07-26']!;

    expect(bucket.goalId, 'g1');
    expect(bucket.timezoneId, 'UTC+07');
    expect(bucket.targetSnapshot, 20);
  });
}
