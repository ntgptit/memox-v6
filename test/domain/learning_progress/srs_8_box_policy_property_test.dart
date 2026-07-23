import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';

/// WBS 5.4.5 — Progress tests: property / boundary / timezone invariants over
/// the whole Leitner policy surface (SRS Policy v1 §§2,5,6,12). The per-row
/// transition assertions live in `srs_8_box_policy_test.dart`; this file proves
/// the invariants those rows collectively imply, exhaustively over every box.
void main() {
  const policy = Srs8BoxPolicy();
  const activatedBoxes = <int>[1, 2, 3, 4, 5, 6, 7, 8];
  // A deliberately non-midnight, non-DST-safe UTC instant: `Duration(days:)`
  // must add exact 24h multiples regardless of wall-clock (§6, day = 24h).
  final now = DateTime.utc(2026, 3, 8, 17, 43, 11);

  group('transition invariants hold for every activated box', () {
    for (final box in activatedBoxes) {
      test('Box $box: correct never lowers the box, ceiling is 8', () {
        final next = policy
            .applyGrade(currentBox: box, grade: SrsGrade.correct, nowUtc: now)
            .box;
        expect(next, greaterThanOrEqualTo(box));
        expect(next, box == 8 ? 8 : box + 1);
        expect(next, lessThanOrEqualTo(8));
      });

      test('Box $box: wrong never raises the box, floor is 1', () {
        final next = policy
            .applyGrade(currentBox: box, grade: SrsGrade.wrong, nowUtc: now)
            .box;
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
          final d = policy.applyGrade(
            currentBox: box,
            grade: grade,
            nowUtc: now,
          );
          expect(
            d.dueAt == null,
            d.box == 8,
            reason: 'only mastered Box 8 carries a null due date',
          );
        });
      }
    }
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
      final d = policy.activate(nowUtc: now);
      expect(d.dueAt!.isUtc, isTrue);
      expect(d.dueAt!.difference(now), const Duration(days: 1));
    });

    intervalDays.forEach((landingBox, days) {
      test('landing in Box $landingBox schedules exactly $days×24h ahead', () {
        // Reach `landingBox` via a correct grade from the box below.
        final d = policy.applyGrade(
          currentBox: landingBox - 1 == 0 ? 1 : landingBox - 1,
          grade: SrsGrade.correct,
          nowUtc: now,
        );
        // Box 1 is only reachable by activation, tested above; skip its promote.
        if (landingBox == 1) return;
        expect(d.box, landingBox);
        expect(d.dueAt!.isUtc, isTrue);
        expect(d.dueAt!.difference(now), Duration(days: days));
      });
    });

    test('mastery (Box 7 correct → Box 8) clears the due date', () {
      final d = policy.applyGrade(
        currentBox: 7,
        grade: SrsGrade.correct,
        nowUtc: now,
      );
      expect(d.box, 8);
      expect(d.dueAt, isNull);
    });
  });

  test(
    'the policy is a pure function — identical inputs, identical output',
    () {
      final a = policy.applyGrade(
        currentBox: 4,
        grade: SrsGrade.wrong,
        nowUtc: now,
      );
      final b = policy.applyGrade(
        currentBox: 4,
        grade: SrsGrade.wrong,
        nowUtc: now,
      );
      expect(a.box, b.box);
      expect(a.dueAt, b.dueAt);
    },
  );
}
