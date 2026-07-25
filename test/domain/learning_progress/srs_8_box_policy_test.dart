import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';

/// WBS 5.4.3 / `TEST-WBS-5.4.3-01` — the `SRS8-v1` decision table.
///
/// Every test names the exact row IDs it covers, as
/// `docs/decision-tables/srs-8-box-v1.md` requires. Rows owned by other
/// work packages are listed at the bottom of this file.
void main() {
  final now = DateTime.utc(2026, 7, 25, 9, 30);

  LearningProgress progressAt(
    int box, {
    DateTime? dueAt,
    int repetitionCount = 0,
    int lapseCount = 0,
    String policyId = leitner8BoxPolicyId,
    DateTime? srsActivatedAt,
    DateTime? lastReviewedAt,
  }) {
    return LearningProgress(
      id: 'progress-1',
      cardId: 'card-1',
      box: box,
      dueAt: dueAt,
      policyId: policyId,
      policyVersion: 1,
      revision: 0,
      repetitionCount: repetitionCount,
      lapseCount: lapseCount,
      lastTerminalAttemptId: null,
      srsActivatedAt: srsActivatedAt,
      lastReviewedAt: lastReviewedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('intervals (§2)', () {
    test('boxes 1..7 are 1, 3, 7, 14, 30, 60, 120 days', () {
      expect(
        List.generate(7, (index) => Srs8BoxPolicy.intervalForBox(index + 1)),
        const [
          Duration(days: 1),
          Duration(days: 3),
          Duration(days: 7),
          Duration(days: 14),
          Duration(days: 30),
          Duration(days: 60),
          Duration(days: 120),
        ],
      );
    });

    test('a day is 24 hours, not a calendar day (§6)', () {
      expect(Srs8BoxPolicy.intervalForBox(1), const Duration(hours: 24));
    });

    test('box 0 and box 8 have no interval to ask for', () {
      for (final box in [Srs8BoxPolicy.newBox, Srs8BoxPolicy.masteredBox]) {
        expect(
          () => Srs8BoxPolicy.intervalForBox(box),
          throwsA(
            isA<ValidationFailure>().having(
              (failure) => failure.code,
              'code',
              'not-scheduled',
            ),
          ),
          reason: 'box $box is not a scheduled box',
        );
      }
    });
  });

  group('activation (SRS8-001, SRS8-002)', () {
    test('SRS8-001: Box 0 activates to Box 1 due in one day', () {
      final schedule = Srs8BoxPolicy.activate(
        current: progressAt(0),
        nowUtc: now,
      );

      expect(schedule.box, 1);
      expect(schedule.dueAt, now.add(const Duration(days: 1)));
      expect(schedule.srsActivatedAt, now);
      expect(schedule.lastReviewedAt, now);
      expect(schedule.policyId, 'leitner-8-box-v1');
    });

    // §3: activation fixes the instant once. Before schema v2 the policy took
    // the activation instant as an optional parameter that no caller ever
    // passed, so it defaulted to null — harmless only because nothing
    // persisted it. The moment v2 began storing the value, that default would
    // have written NULL over a real activation on every grade. It now reads
    // from `current`, and these two tests hold that line.
    test('a later grade carries the activation instant through', () {
      final activated = now.subtract(const Duration(days: 30));

      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(3, dueAt: now, srsActivatedAt: activated),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      expect(schedule.srsActivatedAt, activated);
      // The review instant, by contrast, is always the grade's own `now`.
      expect(schedule.lastReviewedAt, now);
    });

    test('a pre-v2 row keeps a null activation rather than acquiring one', () {
      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(3, dueAt: now),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      expect(schedule.srsActivatedAt, isNull);
    });

    test('activation counts neither a repetition nor a lapse', () {
      final schedule = Srs8BoxPolicy.activate(
        current: progressAt(0, repetitionCount: 0, lapseCount: 0),
        nowUtc: now,
      );

      expect(schedule.repetitionCount, 0);
      expect(schedule.lapseCount, 0);
    });

    test('SRS8-002: an already-activated card is not re-activated', () {
      expect(
        () => Srs8BoxPolicy.activate(current: progressAt(3), nowUtc: now),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.code,
            'code',
            'already-activated',
          ),
        ),
      );
    });
  });

  group('box transitions (§5)', () {
    // The full promote/demote table, one case per decision row.
    const rows = <({String id, int from, SrsGrade grade, int to, int? days})>[
      (id: 'SRS8-003', from: 1, grade: SrsGrade.correct, to: 2, days: 3),
      (id: 'SRS8-004', from: 1, grade: SrsGrade.wrong, to: 1, days: 1),
      (id: 'SRS8-017', from: 2, grade: SrsGrade.correct, to: 3, days: 7),
      (id: 'SRS8-018', from: 2, grade: SrsGrade.wrong, to: 1, days: 1),
      (id: 'SRS8-019', from: 3, grade: SrsGrade.correct, to: 4, days: 14),
      (id: 'SRS8-020', from: 3, grade: SrsGrade.wrong, to: 2, days: 3),
      (id: 'SRS8-005', from: 4, grade: SrsGrade.correct, to: 5, days: 30),
      (id: 'SRS8-006', from: 4, grade: SrsGrade.wrong, to: 3, days: 7),
      (id: 'SRS8-021', from: 5, grade: SrsGrade.correct, to: 6, days: 60),
      (id: 'SRS8-022', from: 5, grade: SrsGrade.wrong, to: 4, days: 14),
      (id: 'SRS8-023', from: 6, grade: SrsGrade.correct, to: 7, days: 120),
      (id: 'SRS8-024', from: 6, grade: SrsGrade.wrong, to: 5, days: 30),
      (id: 'SRS8-007', from: 7, grade: SrsGrade.correct, to: 8, days: null),
      // No decision-table row owns Box 7 + wrong, though the table calls
      // itself the complete v1 contract. §5's formula settles the
      // behaviour unambiguously — max(7 - 1, 1) = 6, +60d — so it is
      // covered here as a derived case and recorded as a table gap.
      (id: '§5 derived', from: 7, grade: SrsGrade.wrong, to: 6, days: 60),
      (id: 'SRS8-008', from: 8, grade: SrsGrade.correct, to: 8, days: null),
      (id: 'SRS8-009', from: 8, grade: SrsGrade.wrong, to: 7, days: 120),
    ];

    for (final row in rows) {
      test('${row.id}: box ${row.from} ${row.grade.name} → box ${row.to}', () {
        final schedule = Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(row.from),
          grade: row.grade,
          nowUtc: now,
        );

        expect(schedule.box, row.to);
        expect(
          schedule.dueAt,
          row.days == null ? isNull : now.add(Duration(days: row.days!)),
        );
      });
    }

    test('every activated box is covered in both directions', () {
      // This assertion is what surfaced the missing Box 7 + wrong row:
      // the cases above must exhaust the (box, grade) space, so a gap in
      // the decision table cannot pass unnoticed as a gap in the suite.
      final covered = {for (final row in rows) (row.from, row.grade)};
      final expected = {
        for (var box = 1; box <= 8; box++) ...[
          (box, SrsGrade.correct),
          (box, SrsGrade.wrong),
        ],
      };
      expect(covered, expected);
    });

    test('correct caps at 8 and wrong floors at 1 — no Box 9, no Box 0', () {
      expect(Srs8BoxPolicy.boxAfterFinalization(8, SrsGrade.correct), 8);
      expect(Srs8BoxPolicy.boxAfterFinalization(1, SrsGrade.wrong), 1);
    });

    test('a Box 0 card is rejected rather than silently activated', () {
      expect(
        () => Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(0),
          grade: SrsGrade.correct,
          nowUtc: now,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.code,
            'code',
            'not-activated',
          ),
        ),
      );
    });
  });

  group('counters (§8)', () {
    test('every terminal grade counts one repetition', () {
      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(3, repetitionCount: 4, lapseCount: 1),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      expect(schedule.repetitionCount, 5);
      expect(schedule.lapseCount, 1, reason: 'correct is not a lapse');
      expect(schedule.lastReviewedAt, now);
    });

    test('wrong counts a lapse as well as a repetition', () {
      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(3, repetitionCount: 4, lapseCount: 1),
        grade: SrsGrade.wrong,
        nowUtc: now,
      );

      expect(schedule.repetitionCount, 5);
      expect(schedule.lapseCount, 2);
    });
  });

  group('terminal grade folding (§4, SRS8-010)', () {
    test('all passes on the first round is correct', () {
      expect(
        Srs8BoxPolicy.terminalGrade(const [
          SrsEvidence.passed,
          SrsEvidence.passed,
        ]),
        SrsGrade.correct,
      );
    });

    test('SRS8-010: wrong is sticky even when a retry passes', () {
      // The exact shape of a mastery loop: missed, then mastered.
      expect(
        Srs8BoxPolicy.terminalGrade(const [
          SrsEvidence.wrong,
          SrsEvidence.passed,
          SrsEvidence.passed,
        ]),
        SrsGrade.wrong,
      );
    });

    test('almost and timeout are lapses too, in any round', () {
      for (final lapse in [SrsEvidence.almost, SrsEvidence.timeout]) {
        expect(
          Srs8BoxPolicy.terminalGrade([SrsEvidence.passed, lapse]),
          SrsGrade.wrong,
          reason: '${lapse.name} must not read as a clean run',
        );
      }
    });

    test('no graded evidence yields no grade, never a free correct', () {
      expect(Srs8BoxPolicy.terminalGrade(const []), isNull);
    });

    test('SRS8-010 end to end: one wrong demotes exactly one box', () {
      final grade = Srs8BoxPolicy.terminalGrade(const [
        SrsEvidence.wrong,
        SrsEvidence.passed,
      ]);
      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(5),
        grade: grade!,
        nowUtc: now,
      );

      expect(schedule.box, 4, reason: 'one decrement, not one per wrong');
      expect(schedule.dueAt, now.add(const Duration(days: 14)));
    });

    test('stickiness does not cross sessions: a clean relearn promotes', () {
      // Session 1 demotes 5 → 4.
      final demoted = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(5),
        grade: Srs8BoxPolicy.terminalGrade(const [SrsEvidence.wrong])!,
        nowUtc: now,
      );
      expect(demoted.box, 4);

      // Session 2 reads the persisted box and folds its own evidence.
      final promoted = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(demoted.box),
        grade: Srs8BoxPolicy.terminalGrade(const [SrsEvidence.passed])!,
        nowUtc: now,
      );
      expect(promoted.box, 5);
    });
  });

  group('policy identity (§1, SRS8-028)', () {
    test('SRS8-028: another policy id is a typed error, not a guess', () {
      for (final call in <void Function()>[
        () => Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(3, policyId: 'fsrs-v2'),
          grade: SrsGrade.correct,
          nowUtc: now,
        ),
        () => Srs8BoxPolicy.activate(
          current: progressAt(0, policyId: 'fsrs-v2'),
          nowUtc: now,
        ),
      ]) {
        expect(
          call,
          throwsA(
            isA<ValidationFailure>()
                .having((failure) => failure.field, 'field', 'policyId')
                .having((failure) => failure.code, 'code', 'unsupported'),
          ),
        );
      }
    });

    test('every schedule stamps the v1 policy id', () {
      expect(
        Srs8BoxPolicy.applyTerminalGrade(
          current: progressAt(2),
          grade: SrsGrade.correct,
          nowUtc: now,
        ).policyId,
        'leitner-8-box-v1',
      );
    });
  });

  group('purity (§12)', () {
    test('the same inputs always produce the same schedule', () {
      SrsSchedule run() => Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(4),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      expect(run().box, run().box);
      expect(run().dueAt, run().dueAt);
      expect(run().dueAt, now.add(const Duration(days: 30)));
    });

    test('due instants stay in UTC', () {
      final schedule = Srs8BoxPolicy.applyTerminalGrade(
        current: progressAt(1),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      expect(schedule.dueAt!.isUtc, isTrue);
      expect(schedule.lastReviewedAt.isUtc, isTrue);
    });
  });
}

// Rows owned elsewhere, so this suite does not claim them:
//   SRS8-011, SRS8-012 — idempotent replay and stale-writer conflict are
//     transaction behaviour (WBS 5.4.4).
//   SRS8-013, SRS8-014, SRS8-015, SRS8-025 — queue eligibility, covered
//     by WBS 5.4.2 in study_queue_counts_usecase_test.dart.
//   SRS8-016 — reset to Box 0 belongs to the reset-progress flow.
//   SRS8-026, SRS8-027 — intermediate attempts and practice outcomes are
//     Study Session history (WBS 5.6).
