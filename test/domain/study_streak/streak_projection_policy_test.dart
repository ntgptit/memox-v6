import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_streak/streak_projection_policy.dart';

/// WBS study-streak — `calculate-current-streak.md`.
///
/// The Study Result screen has shipped a streak card since it was built, but
/// nothing in production ever computed one: `StudyResultGoalStatus` was
/// constructed in exactly one place, the parity fixture override. This is the
/// policy half of closing that.
///
/// §5's state matrix is the test list: zero, first day, active multi-day,
/// broken, historical longest, duplicate/unsorted/future records, and the
/// calendar boundaries.
void main() {
  const policy = StreakProjectionPolicy();
  const today = StreakDay(2026, 7, 26);

  StreakProjection project(List<StreakDay> days, {StreakDay at = today}) =>
      policy.project(days: days, effectiveDay: at);

  test('empty history is 0/0 with no last day', () {
    final result = project(<StreakDay>[]);

    expect(result.current, 0);
    expect(result.longest, 0);
    expect(result.lastQualifiedDay, isNull);
  });

  test('a single day today is a streak of one', () {
    final result = project(<StreakDay>[today]);

    expect(result.current, 1);
    expect(result.longest, 1);
    expect(result.lastQualifiedDay, today);
  });

  test('consecutive days accumulate', () {
    final result = project(<StreakDay>[
      const StreakDay(2026, 7, 24),
      const StreakDay(2026, 7, 25),
      today,
    ]);

    expect(result.current, 3);
    expect(result.longest, 3);
  });

  test('a one-day gap closes the run', () {
    // 24th qualified, 25th did not, 26th did: the current run is just today.
    final result = project(<StreakDay>[const StreakDay(2026, 7, 24), today]);

    expect(result.current, 1);
    expect(result.longest, 1);
  });

  // §6: "broken current không xóa longest".
  test('a broken current run leaves longest intact', () {
    final result = project(<StreakDay>[
      const StreakDay(2026, 7, 1),
      const StreakDay(2026, 7, 2),
      const StreakDay(2026, 7, 3),
      const StreakDay(2026, 7, 4),
      const StreakDay(2026, 7, 20),
    ]);

    expect(result.current, 0, reason: 'the 20th is long past the grace window');
    expect(result.longest, 4);
    expect(result.lastQualifiedDay, const StreakDay(2026, 7, 20));
  });

  test('yesterday still counts, the day before does not', () {
    // The grace window is the one rule no business doc pins a length to; it is
    // asserted here so changing `graceDays` has to be a deliberate act.
    expect(project(<StreakDay>[const StreakDay(2026, 7, 25)]).current, 1);
    expect(project(<StreakDay>[const StreakDay(2026, 7, 24)]).current, 0);
  });

  test('duplicate and unsorted records normalize before counting', () {
    final result = project(<StreakDay>[
      today,
      const StreakDay(2026, 7, 24),
      today,
      const StreakDay(2026, 7, 25),
      const StreakDay(2026, 7, 24),
    ]);

    expect(result.current, 3, reason: 'one local day contributes at most once');
    expect(result.longest, 3);
  });

  test('a future record is dropped and reported, not counted', () {
    final result = project(<StreakDay>[
      const StreakDay(2026, 7, 25),
      today,
      const StreakDay(2026, 7, 27),
    ]);

    expect(result.current, 2);
    expect(result.lastQualifiedDay, today);
    expect(result.issues, hasLength(1));
    expect(result.issues.single.day, const StreakDay(2026, 7, 27));
  });

  test('a future record does not deny the streak the other days earned', () {
    // The whole reason issues are returned rather than thrown.
    final result = project(<StreakDay>[
      const StreakDay(2026, 7, 25),
      today,
      const StreakDay(2030, 1, 1),
    ]);

    expect(result.current, 2);
    expect(result.issues, hasLength(1));
  });

  test('runs cross month and year boundaries', () {
    final result = project(<StreakDay>[
      const StreakDay(2025, 12, 30),
      const StreakDay(2025, 12, 31),
      const StreakDay(2026, 1, 1),
    ], at: const StreakDay(2026, 1, 1));

    expect(result.current, 3);
    expect(result.longest, 3);
  });

  test('the projection is deterministic across input orderings', () {
    final ascending = project(<StreakDay>[
      const StreakDay(2026, 7, 24),
      const StreakDay(2026, 7, 25),
      today,
    ]);
    final descending = project(<StreakDay>[
      today,
      const StreakDay(2026, 7, 25),
      const StreakDay(2026, 7, 24),
    ]);

    expect(ascending.current, descending.current);
    expect(ascending.longest, descending.longest);
    expect(ascending.lastQualifiedDay, descending.lastQualifiedDay);
  });

  test('reading does not mutate the records it was given', () {
    final days = <StreakDay>[today, const StreakDay(2026, 7, 24)];
    project(days);

    expect(days, <StreakDay>[today, const StreakDay(2026, 7, 24)]);
  });

  test('the projection carries its formula version', () {
    expect(
      project(<StreakDay>[today]).formulaVersion,
      StreakProjectionPolicy.formulaVersion,
    );
  });

  group('StreakDay', () {
    test('next rolls over months, years and leap days', () {
      expect(const StreakDay(2026, 1, 31).next, const StreakDay(2026, 2, 1));
      expect(const StreakDay(2026, 12, 31).next, const StreakDay(2027, 1, 1));
      expect(const StreakDay(2024, 2, 28).next, const StreakDay(2024, 2, 29));
    });

    test('a local date drops the time of day', () {
      expect(
        StreakDay.of(DateTime(2026, 7, 26, 23, 59)),
        StreakDay.of(DateTime(2026, 7, 26, 0, 1)),
      );
    });
  });
}
