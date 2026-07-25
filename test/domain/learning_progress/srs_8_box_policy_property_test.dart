import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';

/// WBS 5.4.5 — Progress tests: property / boundary / timezone invariants over
/// the whole Leitner policy surface (SRS Policy v1 §§2,5,6,12). The per-row
/// transition assertions live in `srs_8_box_policy_test.dart`; this file proves
/// the invariants those rows collectively imply, exhaustively over every box.
void main() {
  const activatedBoxes = <int>[1, 2, 3, 4, 5, 6, 7, 8];
  // A deliberately non-midnight, non-DST-safe UTC instant: `Duration(days:)`
  // must add exact 24h multiples regardless of wall-clock (§6, day = 24h).
  final now = DateTime.utc(2026, 3, 8, 17, 43, 11);

  LearningProgress progressAt(int box, {DateTime? srsActivatedAt}) {
    return LearningProgress(
      id: 'progress-1',
      cardId: 'card-1',
      box: box,
      // Boxes 1..7 must carry a due date to satisfy the schema CHECK; the
      // policy reads only the box, so any past instant is representative.
      dueAt: box >= 1 && box <= 7
          ? now.subtract(const Duration(days: 1))
          : null,
      policyId: leitner8BoxPolicyId,
      policyVersion: 1,
      revision: 0,
      repetitionCount: 0,
      lapseCount: 0,
      lastTerminalAttemptId: null,
      srsActivatedAt: srsActivatedAt,
      lastReviewedAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('transition invariants hold for every activated box', () {
    for (final box in activatedBoxes) {
      test('Box $box: correct never lowers the box, ceiling is 8', () {
        final next = Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(box),
          grade: SrsGrade.correct,
          nowUtc: now,
        ).box;
        expect(next, greaterThanOrEqualTo(box));
        expect(next, box == 8 ? 8 : box + 1);
        expect(next, lessThanOrEqualTo(8));
      });

      test('Box $box: wrong never raises the box, floor is 1', () {
        final next = Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(box),
          grade: SrsGrade.wrong,
          nowUtc: now,
        ).box;
        expect(next, lessThanOrEqualTo(box));
        expect(next, box == 1 ? 1 : box - 1);
        expect(next, greaterThanOrEqualTo(1));
      });
    }
  });

  group('schedule invariant matches the schema box/due CHECK', () {
    // learning_progress CHECK: box 8 has no due; box 1..7 must have one.
    for (final box in activatedBoxes) {
      for (final grade in SrsGrade.values) {
        test('Box $box $grade lands on a schema-legal (box, due) pair', () {
          final schedule = Srs8BoxPolicy.applyTerminalGrade(
            current: progressAt(box),
            grade: grade,
            nowUtc: now,
          );
          expect(
            schedule.dueAt == null,
            schedule.box == 8,
            reason: 'only mastered Box 8 carries a null due date',
          );
        });
      }
    }
  });

  group('counter invariants (§8)', () {
    for (final box in activatedBoxes) {
      test('Box $box: every terminal grade counts exactly one repetition', () {
        for (final grade in SrsGrade.values) {
          expect(
            Srs8BoxPolicy.applyTerminalGrade(
              current: progressAt(box),
              grade: grade,
              nowUtc: now,
            ).repetitionCount,
            1,
          );
        }
      });

      test('Box $box: only a wrong grade counts a lapse', () {
        expect(
          Srs8BoxPolicy.applyTerminalGrade(
            current: progressAt(box),
            grade: SrsGrade.correct,
            nowUtc: now,
          ).lapseCount,
          0,
        );
        expect(
          Srs8BoxPolicy.applyTerminalGrade(
            current: progressAt(box),
            grade: SrsGrade.wrong,
            nowUtc: now,
          ).lapseCount,
          1,
        );
      });
    }

    test('activation is not a graded repetition — counters are untouched', () {
      final schedule = Srs8BoxPolicy.activate(
        current: progressAt(Srs8BoxPolicy.newBox),
        nowUtc: now,
      );
      expect(schedule.repetitionCount, 0);
      expect(schedule.lapseCount, 0);
    });
  });

  group('timezone / UTC contract (§6, day = 24h)', () {
    // Expected interval in days for landing in box 1..7.
    const intervalDays = <int, int>{
      1: 1,
      2: 3,
      3: 7,
      4: 14,
      5: 30,
      6: 60,
      7: 120,
    };

    test('activation due is exactly 24h ahead, in UTC', () {
      final schedule = Srs8BoxPolicy.activate(
        current: progressAt(Srs8BoxPolicy.newBox),
        nowUtc: now,
      );
      expect(schedule.dueAt!.isUtc, isTrue);
      expect(schedule.dueAt!.difference(now), const Duration(days: 1));
    });

    intervalDays.forEach((landingBox, days) {
      test('landing in Box $landingBox schedules exactly $days×24h ahead', () {
        // Box 1 is only reachable by activation, covered above.
        if (landingBox == 1) return;
        final schedule = Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(landingBox - 1),
          grade: SrsGrade.correct,
          nowUtc: now,
        );
        expect(schedule.box, landingBox);
        expect(schedule.dueAt!.isUtc, isTrue);
        expect(schedule.dueAt!.difference(now), Duration(days: days));
      });
    });

    test('mastery (Box 7 correct → Box 8) clears the due date', () {
      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(7),
        grade: SrsGrade.correct,
        nowUtc: now,
      );
      expect(schedule.box, 8);
      expect(schedule.dueAt, isNull);
    });
  });

  test(
    'the policy is a pure function — identical inputs, identical output',
    () {
      final a = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(4),
        grade: SrsGrade.wrong,
        nowUtc: now,
      );
      final b = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(4),
        grade: SrsGrade.wrong,
        nowUtc: now,
      );
      expect(a.box, b.box);
      expect(a.dueAt, b.dueAt);
      expect(a.repetitionCount, b.repetitionCount);
      expect(a.lapseCount, b.lapseCount);
    },
  );
}
