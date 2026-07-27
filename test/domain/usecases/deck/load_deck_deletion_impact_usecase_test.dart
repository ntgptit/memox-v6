import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';

/// WBS 6.1 — the delete impact derives the deck state and totals the subtree it
/// would remove (delete-deck.md §4).
void main() {
  LoadDeckDeletionImpactUseCase build({
    required int directChildren,
    required int directCards,
    required int subtreeCards,
    required int subtreeDecks,
    int studiedCards = 0,
    StudySession? activeSession,
    List<Deck> sessionAncestors = const <Deck>[],
  }) => LoadDeckDeletionImpactUseCase(
    decks: _FakeDecks(
      counts: DeckContentCounts(
        childDeckCount: directChildren,
        activeCardCount: directCards,
      ),
      subtreeCards: subtreeCards,
      subtreeDecks: subtreeDecks,
      studiedCards: studiedCards,
      sessionChain: sessionAncestors,
    ),
    sessions: _FakeSessions(activeSession),
  );

  test('an empty deck reports the empty state with zero totals', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 0,
      subtreeCards: 0,
      subtreeDecks: 0,
    ).call('d1');
    expect(impact.state, DeckContentState.empty);
    expect(impact.cardCount, 0);
    expect(impact.deckCount, 0);
  });

  test('a leaf reports its card total', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 4,
      subtreeCards: 4,
      subtreeDecks: 0,
    ).call('d1');
    expect(impact.state, DeckContentState.leaf);
    expect(impact.cardCount, 4);
    expect(impact.deckCount, 0);
  });

  test('a parent reports nested decks + subtree cards', () async {
    final impact = await build(
      directChildren: 2,
      directCards: 0,
      subtreeCards: 9,
      subtreeDecks: 3,
    ).call('d1');
    expect(impact.state, DeckContentState.parent);
    expect(impact.cardCount, 9);
    expect(impact.deckCount, 3);
  });
  // `delete-deck.md` §1 asks the copy to name the learning progress removed.
  // Counting progress rows would restate the card total — every card has one
  // from creation — so the impact counts cards past Box 0.
  test('the studied count is carried through', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 4,
      subtreeCards: 4,
      subtreeDecks: 0,
      studiedCards: 2,
    ).call('d1');

    expect(impact.cardCount, 4);
    expect(impact.studiedCardCount, 2);
  });

  // `delete-deck.md` §1 requires an impact summary and §5 enumerates what goes
  // with the deck. A running session's committed answers go too — the delete
  // chain removes its row, snapshots and attempts — and that was the one loss
  // the summary never named (`int-34`).
  test('a session in the deck itself is named as a loss', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 3,
      subtreeCards: 3,
      subtreeDecks: 0,
      activeSession: _session('d1'),
    ).call('d1');
    expect(impact.endsRunningSession, isTrue);
  });

  test('a session in a descendant is named too', () async {
    final impact = await build(
      directChildren: 1,
      directCards: 0,
      subtreeCards: 3,
      subtreeDecks: 1,
      activeSession: _session('child'),
      sessionAncestors: <Deck>[_deck('d1')],
    ).call('d1');
    expect(impact.endsRunningSession, isTrue);
  });

  // A session rooted elsewhere keeps its own row and can still finish from its
  // snapshot (ST-CHG-002), so the delete does not end it.
  test('a session outside the subtree is not a loss', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 3,
      subtreeCards: 3,
      subtreeDecks: 0,
      activeSession: _session('other'),
      sessionAncestors: <Deck>[_deck('somewhere-else')],
    ).call('d1');
    expect(impact.endsRunningSession, isFalse);
  });

  test('no session at all is not a loss', () async {
    final impact = await build(
      directChildren: 0,
      directCards: 3,
      subtreeCards: 3,
      subtreeDecks: 0,
    ).call('d1');
    expect(impact.endsRunningSession, isFalse);
  });
}

class _FakeDecks implements DeckRepository {
  _FakeDecks({
    required this.counts,
    required this.subtreeCards,
    required this.subtreeDecks,
    this.studiedCards = 0,
    this.sessionChain = const <Deck>[],
  });
  final DeckContentCounts counts;
  final int subtreeCards;
  final int subtreeDecks;

  /// Cards past Box 0 — the learning progress the confirm has to name.
  final int studiedCards;

  /// The chain returned for the active session's deck.
  final List<Deck> sessionChain;

  @override
  Future<List<Deck>> ancestors(String deckId) async => sessionChain;

  @override
  Future<DeckContentCounts> contentCounts(String deckId) async => counts;
  @override
  Future<int> countSubtreeCards(String deckId) async => subtreeCards;
  @override
  Future<int> countSubtreeDecks(String deckId) async => subtreeDecks;

  @override
  Future<int> countSubtreeStudiedCards(String deckId) async => studiedCards;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}

Deck _deck(String id) => Deck(
  id: id,
  languagePairId: 'lp1',
  parentId: null,
  name: id,
  normalizedName: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

StudySession _session(String deckId) => StudySession(
  id: 's1',
  type: SessionType.newLearning,
  deckId: deckId,
  scope: SessionScope.subtree,
  state: SessionState.active,
  revision: 0,
  snapshotVersion: 1,
  scheduleSrs: true,
  startedAt: DateTime.utc(2026),
  finalizedAt: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Answers only the active-session question the impact asks.
class _FakeSessions implements StudySessionRepository {
  const _FakeSessions(this._active);

  final StudySession? _active;

  @override
  Future<StudySession?> activeSession() async => _active;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}
