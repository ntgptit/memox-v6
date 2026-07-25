import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/canonical_mode_evidence.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_strategy_base.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// WBS 5.5.2 — the pure strategy template runs exactly
/// `validate → evaluate → mapCanonicalEvidence`, in order, with no persistence
/// or side effects (factory-di-architecture §3).
void main() {
  test('the template runs the three steps in order and returns evidence', () {
    final trace = <String>[];
    final strategy = _RecordingStrategy(trace);

    final evidence = strategy.evaluate(
      const _FakeInput(cardId: 'c1', roundIndex: 0, eventId: 'e1'),
    );

    expect(trace, <String>['validate', 'assess', 'map']);
    expect(evidence.mode, StudyModeType.guess);
    expect(evidence.outcome, ModeOutcome.correct);
    expect(evidence.cardId, 'c1');
    expect(evidence.eventId, 'e1');
  });

  test('a validation failure short-circuits before evaluate/map', () {
    final trace = <String>[];
    final strategy = _RecordingStrategy(trace, rejectValidation: true);

    expect(
      () => strategy.evaluate(
        const _FakeInput(cardId: 'c1', roundIndex: 0, eventId: 'e1'),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(trace, <String>[
      'validate',
    ], reason: 'no step runs after a rejection');
  });
}

class _FakeInput implements StudyModeInput {
  const _FakeInput({
    required this.cardId,
    required this.roundIndex,
    required this.eventId,
  });

  @override
  StudyModeType get mode => StudyModeType.guess;
  @override
  String get sessionId => 's1';
  @override
  final String cardId;
  @override
  final int roundIndex;
  @override
  final String eventId;
}

/// A minimal strategy that records which template steps ran, so ordering and
/// short-circuiting are observable.
base class _RecordingStrategy extends StudyModeStrategyBase<_FakeInput, bool> {
  _RecordingStrategy(this._trace, {this.rejectValidation = false});

  final List<String> _trace;
  final bool rejectValidation;

  @override
  StudyModeType get mode => StudyModeType.guess;

  @override
  _FakeInput validate(StudyModeInput input) {
    _trace.add('validate');
    if (rejectValidation) {
      throw ValidationFailure(field: 'input', code: 'unsupported');
    }
    return input as _FakeInput;
  }

  @override
  bool assess(_FakeInput input) {
    _trace.add('assess');
    return true;
  }

  @override
  CanonicalModeEvidence mapCanonicalEvidence(_FakeInput input, bool result) {
    _trace.add('map');
    return CanonicalModeEvidence(
      mode: mode,
      outcome: result ? ModeOutcome.correct : ModeOutcome.wrong,
      cardId: input.cardId,
      roundIndex: input.roundIndex,
      eventId: input.eventId,
      mappingVersion: 1,
    );
  }
}
