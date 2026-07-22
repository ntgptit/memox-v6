import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_snapshot_builder.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';

/// WBS 5.6.2 (domain part) — the pure start-snapshot assembly
/// (`start-study-session.md` §7).
void main() {
  late _SeqIds ids;
  late SessionSnapshotBuilder builder;
  final now = DateTime.utc(2026, 7, 23, 10);

  List<EligibleCard> cards(int n) => List<EligibleCard>.generate(
    n,
    (i) => EligibleCard(
      cardId: 'c$i',
      term: 'term$i',
      meaning: 'meaning$i',
      contentVersion: 1,
      progressBox: 0,
      progressRevision: 0,
    ),
  );

  setUp(() {
    ids = _SeqIds();
    builder = SessionSnapshotBuilder(idGenerator: ids);
  });

  test('newLearning snapshot: base order pinned, session SRS-scheduling', () {
    final snapshot = builder.build(
      sessionId: 'sess-1',
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.newLearning,
      eligibleCards: cards(5),
      initialRoundIndex: 0,
      nowUtc: now,
    );

    // Base snapshot keeps the caller's order; displayOrder is 0..n-1.
    expect(snapshot.cardSnapshots.map((c) => c.cardId).toList(), <String>[
      'c0',
      'c1',
      'c2',
      'c3',
      'c4',
    ]);
    expect(snapshot.cardSnapshots.map((c) => c.displayOrder).toList(), <int>[
      0,
      1,
      2,
      3,
      4,
    ]);

    // Session is active, SRS-scheduling, revision 0.
    expect(snapshot.session.state, SessionState.active);
    expect(snapshot.session.scheduleSrs, isTrue);
    expect(snapshot.session.revision, 0);
    expect(snapshot.session.startedAt, now);

    // Initial order is a permutation of the same cards (Review is stage one).
    expect(snapshot.initialOrder.roundIndex, 0);
    expect(snapshot.initialOrder.cardIds.toSet(), {
      'c0',
      'c1',
      'c2',
      'c3',
      'c4',
    });
  });

  test('the initial order is deterministic for the same session/stage', () {
    StartSessionSnapshot make() =>
        SessionSnapshotBuilder(idGenerator: _SeqIds()).build(
          sessionId: 'sess-x',
          deckId: 'd1',
          scope: SessionScope.leaf,
          type: SessionType.newLearning,
          eligibleCards: cards(6),
          initialRoundIndex: 0,
          nowUtc: now,
        );
    expect(make().initialOrder.cardIds, make().initialOrder.cardIds);
  });

  test(
    'practice snapshot does not schedule SRS and uses the selected mode',
    () {
      final snapshot = builder.build(
        sessionId: 'sess-2',
        deckId: 'd1',
        scope: SessionScope.leaf,
        type: SessionType.practice,
        selectedMode: StudyModeType.fill,
        eligibleCards: cards(3),
        initialRoundIndex: 1,
        nowUtc: now,
      );
      expect(snapshot.session.scheduleSrs, isFalse);
      expect(snapshot.initialOrder.roundIndex, 1);
    },
  );

  test('a single card is never reordered by the initial shuffle', () {
    final snapshot = builder.build(
      sessionId: 'sess-3',
      deckId: 'd1',
      scope: SessionScope.leaf,
      type: SessionType.dueReview,
      eligibleCards: cards(1),
      initialRoundIndex: 1,
      nowUtc: now,
    );
    expect(snapshot.initialOrder.cardIds, <String>['c0']);
    expect(snapshot.session.scheduleSrs, isTrue);
  });
}

/// A deterministic id source: sequential ids so snapshots are reproducible.
class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id-${_n++}';
}
