import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';
import 'package:memox_v6/domain/usecases/study_streak/record_streak_day_usecase.dart';

/// WBS study-streak — `record-streak-day.md`, with `metrics-v1` supplying the
/// qualification rule. §5's state matrix is the test list: first event,
/// same-day repeat, late event, duplicate retry, midnight/timezone, malformed
/// event, storage failure.
class _FakeStreakRepository implements StreakRepository {
  final List<StreakDay> days = <StreakDay>[];
  Object? failWith;

  @override
  Future<void> recordDay(StreakDay day, {required DateTime recordedAt}) async {
    final failure = failWith;
    if (failure != null) throw failure;
    // Mirrors the schema's `local_date` UNIQUE plus `ON CONFLICT DO NOTHING`:
    // a second write for a day already stored is absorbed, not an error.
    if (days.any((stored) => stored.localDate == day.localDate)) return;
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

class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

void main() {
  late _FakeStreakRepository repository;
  late RecordStreakDayUseCase usecase;

  // +07:00: far enough from UTC that a late-evening session lands on a
  // different UTC date, which is exactly the confusion §1 forbids.
  const zone = FixedOffsetTimeZone(id: 'UTC+07', offset: Duration(hours: 7));

  setUp(() {
    repository = _FakeStreakRepository();
    usecase = RecordStreakDayUseCase(
      streaks: repository,
      timeZone: zone,
      idGenerator: _SequentialIds(),
    );
  });

  Future<RecordStreakDayResult> record({
    SessionType type = SessionType.newLearning,
    int cards = 3,
    String sessionId = 's1',
    DateTime? at,
  }) => usecase(
    sessionId: sessionId,
    sessionType: type,
    qualifiedCardCount: cards,
    finalizedAt: at ?? DateTime.utc(2026, 7, 26, 3),
  );

  test('a finalized qualifying session marks the day', () async {
    expect(await record(), RecordStreakDayResult.recorded);
    expect(repository.days.single.localDate, '2026-07-26');
    expect(repository.days.single.timezoneId, 'UTC+07');
    expect(repository.days.single.qualifiedSource, 's1');
  });

  test('a second session the same day is an idempotent success', () async {
    await record();
    final again = await record(sessionId: 's2', type: SessionType.dueReview);

    expect(again, RecordStreakDayResult.alreadyQualified);
    expect(repository.days, hasLength(1), reason: 'one day, one record');
  });

  test('the same event retried does not double-count', () async {
    await record();
    expect(await record(), RecordStreakDayResult.alreadyQualified);
    expect(repository.days, hasLength(1));
  });

  test('practice never contributes', () async {
    expect(
      await record(type: SessionType.practice),
      RecordStreakDayResult.notQualifying,
    );
    expect(repository.days, isEmpty);
  });

  test('dueReview and relearn both qualify', () async {
    expect(
      await record(type: SessionType.dueReview),
      isNot(RecordStreakDayResult.notQualifying),
    );
    repository.days.clear();
    expect(
      await record(type: SessionType.relearn),
      isNot(RecordStreakDayResult.notQualifying),
    );
  });

  // `metrics-v1`: a day qualifies on "at least one qualified Card". A session
  // that finalized without anyone answering anything is not a day's study.
  test('a session with no qualified card does not mark the day', () async {
    expect(await record(cards: 0), RecordStreakDayResult.notQualifying);
    expect(repository.days, isEmpty);
  });

  // §1: the identity is the calendar date in the timezone contract, never the
  // raw UTC date.
  test('the day is the local one, not the UTC one', () async {
    // 22:00 UTC on the 26th is 05:00 on the 27th at +07:00.
    await record(at: DateTime.utc(2026, 7, 26, 22));

    expect(repository.days.single.localDate, '2026-07-27');
  });

  test('two sessions either side of local midnight mark two days', () async {
    // 16:00 UTC = 23:00 local on the 26th; 18:00 UTC = 01:00 local on the 27th.
    await record(at: DateTime.utc(2026, 7, 26, 16));
    await record(sessionId: 's2', at: DateTime.utc(2026, 7, 26, 18));

    expect(repository.days.map((d) => d.localDate), <String>[
      '2026-07-26',
      '2026-07-27',
    ]);
  });

  // §4: "Late event được ghi rồi chuyển sang reconciliation nếu ảnh hưởng lịch
  // sử" — a late arrival still marks the day it belonged to.
  test('a late event marks its own day, not today', () async {
    await record(at: DateTime.utc(2026, 7, 20, 3));

    expect(repository.days.single.localDate, '2026-07-20');
  });

  test('the record carries its policy version', () async {
    await record();

    expect(
      repository.days.single.sourceVersion,
      RecordStreakDayUseCase.sourceVersion,
    );
  });

  // §4: "Storage failure vào retry queue với cùng identity". The use case
  // surfaces the failure; isolating it is the finalize caller's job, and that
  // boundary is asserted in the finalize test.
  test('a storage failure propagates rather than reporting success', () async {
    repository.failWith = StateError('disk full');

    await expectLater(record(), throwsA(isA<StateError>()));
    expect(repository.days, isEmpty);
  });
}
