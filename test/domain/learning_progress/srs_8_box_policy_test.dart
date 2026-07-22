import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';

/// WBS 5.4.3 — Leitner 8-box scheduling policy. Each expectation cites the
/// exact decision-table row it enforces (`docs/decision-tables/srs-8-box-v1.md`,
/// SRS8-001, 003–009, 017–024).
void main() {
  const policy = Srs8BoxPolicy();
  // A fixed UTC instant so `nowUtc + Nd` is exact and timezone-independent.
  final now = DateTime.utc(2026, 7, 23, 8);

  DateTime plusDays(int d) => now.add(Duration(days: d));

  group('activation (Box 0 → Box 1)', () {
    test('SRS8-001: activate lands in Box 1, due in one day', () {
      final r = policy.activate(nowUtc: now);
      expect(r.box, 1);
      expect(r.dueAt, plusDays(1));
    });
  });

  group('correct promotes one box with its interval', () {
    // SRS8-003, 017, 019, 005, 021, 023, 007, 008.
    final cases = <int, ({int box, int? days})>{
      1: (box: 2, days: 3), // SRS8-003
      2: (box: 3, days: 7), // SRS8-017
      3: (box: 4, days: 14), // SRS8-019
      4: (box: 5, days: 30), // SRS8-005
      5: (box: 6, days: 60), // SRS8-021
      6: (box: 7, days: 120), // SRS8-023
      7: (box: 8, days: null), // SRS8-007 → mastered
      8: (box: 8, days: null), // SRS8-008 → stays mastered
    };
    cases.forEach((from, expected) {
      test('Box $from correct → Box ${expected.box}', () {
        final r = policy.applyGrade(
          currentBox: from,
          grade: SrsGrade.correct,
          nowUtc: now,
        );
        expect(r.box, expected.box);
        expect(
          r.dueAt,
          expected.days == null ? isNull : plusDays(expected.days!),
        );
      });
    });
  });

  group('wrong demotes one box (sticky floor at Box 1)', () {
    // SRS8-004, 018, 020, 006, 022, 024, (7→6), 009.
    final cases = <int, ({int box, int days})>{
      1: (box: 1, days: 1), // SRS8-004 sticky
      2: (box: 1, days: 1), // SRS8-018
      3: (box: 2, days: 3), // SRS8-020
      4: (box: 3, days: 7), // SRS8-006
      5: (box: 4, days: 14), // SRS8-022
      6: (box: 5, days: 30), // SRS8-024
      7: (box: 6, days: 60), // demote pattern (interval of resulting box)
      8: (box: 7, days: 120), // SRS8-009
    };
    cases.forEach((from, expected) {
      test('Box $from wrong → Box ${expected.box}', () {
        final r = policy.applyGrade(
          currentBox: from,
          grade: SrsGrade.wrong,
          nowUtc: now,
        );
        expect(r.box, expected.box);
        expect(r.dueAt, plusDays(expected.days));
      });
    });
  });

  group('preconditions', () {
    test('a grade on the pre-SRS Box 0 is a contract violation', () {
      expect(
        () => policy.applyGrade(
          currentBox: 0,
          grade: SrsGrade.correct,
          nowUtc: now,
        ),
        throwsArgumentError,
      );
    });

    test('a grade on an out-of-range box is a contract violation', () {
      expect(
        () => policy.applyGrade(
          currentBox: 9,
          grade: SrsGrade.wrong,
          nowUtc: now,
        ),
        throwsArgumentError,
      );
    });
  });
}
