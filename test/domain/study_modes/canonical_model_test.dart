import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// WBS 5.5.1 — canonical mode/evidence model: the closed mode enum and the
/// typed outcome/evidence/metadata the whole subsystem shares
/// (factory-di-architecture §1, `map-mode-outcome.md` §§2,3).
void main() {
  group('StudyModeType', () {
    test('is exactly the six specified modes', () {
      expect(StudyModeType.values.map((m) => m.id).toList(), <String>[
        'review',
        'match',
        'guess',
        'recall',
        'fill',
        'srsBinaryReview',
      ]);
    });

    test('ids round-trip and unknown ids fail closed to null', () {
      for (final mode in StudyModeType.values) {
        expect(StudyModeType.tryFromId(mode.id), mode);
      }
      expect(StudyModeType.tryFromId('practice'), isNull);
      expect(StudyModeType.tryFromId(''), isNull);
    });
  });

  group('ModeOutcome', () {
    test('is exactly the four canonical outcomes', () {
      expect(ModeOutcome.values.map((o) => o.id).toSet(), {
        'reviewed',
        'correct',
        'wrong',
        'almost',
      });
    });

    test('presentation-only actions are not canonical outcomes', () {
      for (final action in <String>['remembered', 'forgot', 'relearn']) {
        expect(ModeOutcome.tryFromId(action), isNull);
      }
    });

    test(
      'the v1 outcome reasons are timeout and duplicateNormalizedMeaning',
      () {
        expect(ModeOutcomeReason.values.map((r) => r.id).toSet(), <String>{
          'timeout',
          'duplicateNormalizedMeaning',
        });
        expect(
          ModeOutcomeReason.tryFromId('timeout'),
          ModeOutcomeReason.timeout,
        );
        expect(
          ModeOutcomeReason.tryFromId('duplicateNormalizedMeaning'),
          ModeOutcomeReason.duplicateNormalizedMeaning,
        );
        expect(ModeOutcomeReason.tryFromId('slow'), isNull);
      },
    );
  });

  group('CanonicalModeEvidence', () {
    test('carries the shared audit fields; pair and reason are optional', () {
      const guess = CanonicalModeEvidence(
        mode: StudyModeType.guess,
        outcome: ModeOutcome.correct,
        cardId: 'c1',
        roundIndex: 0,
        eventId: 'e1',
        mappingVersion: 1,
      );
      expect(guess.pairId, isNull);
      expect(guess.reason, isNull);
      expect(guess.outcome, ModeOutcome.correct);

      const recallTimeout = CanonicalModeEvidence(
        mode: StudyModeType.recall,
        outcome: ModeOutcome.wrong,
        cardId: 'c2',
        roundIndex: 2,
        eventId: 'e2',
        mappingVersion: 1,
        reason: ModeOutcomeReason.timeout,
      );
      expect(recallTimeout.reason, ModeOutcomeReason.timeout);
      expect(recallTimeout.roundIndex, 2);

      const matchPair = CanonicalModeEvidence(
        mode: StudyModeType.match,
        outcome: ModeOutcome.almost,
        cardId: 'c3',
        pairId: 'pair-3',
        roundIndex: 1,
        eventId: 'e3',
        mappingVersion: 1,
      );
      expect(matchPair.pairId, 'pair-3');
      expect(matchPair.outcome, ModeOutcome.almost);
    });
  });
}
