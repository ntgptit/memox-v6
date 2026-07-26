import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/study_queue_counts.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/today/start_review_from_today_usecase.dart';
import 'package:memox_v6/domain/today/start_review_outcome.dart';

/// WBS 5.7.3 — `Start review` recomputes eligibility before it hands off
/// (`start-review-from-today.md` §1: the dashboard count is only a
/// projection).
void main() {
  final now = DateTime.utc(2026, 7, 26, 10);

  final pair = LanguagePair(
    id: 'lp1',
    learningLanguageCode: 'en',
    nativeLanguageCode: 'vi',
    normalizedPairKey: 'en|vi',
    createdAt: now,
    updatedAt: now,
  );

  Deck deck(String id) => Deck(
    id: id,
    languagePairId: 'lp1',
    parentId: null,
    name: id,
    normalizedName: id,
    createdAt: now,
    updatedAt: now,
  );

  StudySession session(String id) => StudySession(
    id: id,
    type: SessionType.dueReview,
    deckId: 'd1',
    scope: SessionScope.subtree,
    state: SessionState.active,
    revision: 0,
    snapshotVersion: 1,
    scheduleSrs: true,
    startedAt: now,
    finalizedAt: null,
    createdAt: now,
    updatedAt: now,
  );

  StartReviewFromTodayUseCase build({
    StudySession? active,
    LanguagePair? activePair,
    List<Deck> roots = const <Deck>[],
    Map<String, int> dueByDeck = const <String, int>{},
    StartStudySessionUseCase? starter,
  }) {
    final progress = _FakeProgress(dueByDeck);
    return StartReviewFromTodayUseCase(
      sessions: _FakeSessions(active),
      decks: _FakeDecks(roots),
      languagePairs: _StubPairs(activePair),
      queueCounts: LoadStudyQueueCountsUseCase(
        progress: progress,
        decks: _FakeDecks(roots),
        clock: _FixedClock(now),
      ),
      startSession: starter ?? _RecordingStart(session('s-new')),
    );
  }

  // §1: an active session decides the answer on its own — the schema allows
  // exactly one, so "start a second" is not a choice to offer.
  test('an active session outranks a new review', () async {
    final starter = _RecordingStart(session('s-new'));
    final outcome = await build(
      active: session('s-active'),
      activePair: pair,
      roots: <Deck>[deck('d1')],
      dueByDeck: <String, int>{'d1': 9},
      starter: starter,
    )();

    expect(outcome, isA<ResumeActiveSession>());
    expect(starter.calls, isEmpty, reason: 'no second session is created');
  });

  // §4: "No longer due chuyển caught-up, không báo lỗi". The dashboard said
  // there were cards; by the time the button was pressed there were not.
  test('a stale count resolves to caught-up, not an error', () async {
    final starter = _RecordingStart(session('s-new'));
    final outcome = await build(
      activePair: pair,
      roots: <Deck>[deck('d1')],
      dueByDeck: <String, int>{'d1': 0},
      starter: starter,
    )();

    expect(outcome, isA<NothingDueNow>());
    expect(starter.calls, isEmpty, reason: 'no empty session is created');
  });

  test('one due deck starts a due-review session over its subtree', () async {
    final starter = _RecordingStart(session('s-new'));
    final outcome = await build(
      activePair: pair,
      roots: <Deck>[deck('d1'), deck('d2')],
      dueByDeck: <String, int>{'d1': 0, 'd2': 6},
      starter: starter,
    )();

    expect(outcome, isA<ReviewStarted>());
    expect(starter.calls.single.deckId, 'd2');
    expect(starter.calls.single.scope, SessionScope.subtree);
    expect(starter.calls.single.type, SessionType.dueReview);
  });

  // `study_sessions.deck_id` is NOT NULL and `scope` is leaf/subtree, so a
  // library-wide session cannot exist. Narrowing silently would start fewer
  // cards than the button advertises.
  test(
    'due cards in several decks ask for a scope instead of guessing',
    () async {
      final starter = _RecordingStart(session('s-new'));
      final outcome = await build(
        activePair: pair,
        roots: <Deck>[deck('d1'), deck('d2'), deck('d3')],
        dueByDeck: <String, int>{'d1': 4, 'd2': 6, 'd3': 0},
        starter: starter,
      )();

      expect(outcome, isA<ChooseReviewScope>());
      final choice = outcome as ChooseReviewScope;
      expect(choice.deckCount, 2);
      // The options carry what the learner needs to choose between, read in
      // the same pass that decided a choice was needed.
      expect(choice.options.map((option) => option.deckId).toList(), <String>[
        'd1',
        'd2',
      ]);
      expect(
        choice.options.map((option) => option.eligibleCount).toList(),
        <int>[4, 6],
      );
      expect(starter.calls, isEmpty);
    },
  );

  // §2 node E → F: a chosen scope skips the picker and starts there.
  test('a chosen deck starts in that deck', () async {
    final starter = _RecordingStart(session('s-new'));
    final outcome = await build(
      activePair: pair,
      roots: <Deck>[deck('d1'), deck('d2')],
      dueByDeck: <String, int>{'d1': 4, 'd2': 6},
      starter: starter,
    )(deckId: 'd2');

    expect(outcome, isA<ReviewStarted>());
    expect(starter.calls.single.deckId, 'd2');
  });

  // §6 forbids a stale count from creating an empty or invalid session. A
  // queue can empty while the picker sits open, so a tapped deck is checked
  // again rather than trusted for having been tapped.
  test('a chosen deck that emptied meanwhile starts nothing', () async {
    final starter = _RecordingStart(session('s-new'));
    final outcome = await build(
      activePair: pair,
      roots: <Deck>[deck('d1'), deck('d2')],
      dueByDeck: <String, int>{'d1': 4, 'd2': 0},
      starter: starter,
    )(deckId: 'd2');

    expect(outcome, isA<NothingDueNow>());
    expect(starter.calls, isEmpty);
  });

  test('no active pair has nothing to review', () async {
    final outcome = await build(roots: <Deck>[deck('d1')])();

    expect(outcome, isA<NothingDueNow>());
  });

  // §6: "Session chỉ do Start Session contract tạo" — a blocked start is that
  // contract's answer, and it reaches the caller rather than being swallowed
  // into a caught-up state that would look like success.
  test('a blocked start propagates rather than reading as caught up', () async {
    final starter = _ThrowingStart();

    await expectLater(
      build(
        activePair: pair,
        roots: <Deck>[deck('d1')],
        dueByDeck: <String, int>{'d1': 6},
        starter: starter,
      )(),
      throwsA(isA<ValidationFailure>()),
    );
  });
}

class _StartCall {
  const _StartCall(this.deckId, this.scope, this.type);

  final String deckId;
  final SessionScope scope;
  final SessionType type;
}

class _RecordingStart implements StartStudySessionUseCase {
  _RecordingStart(this._session);

  final StudySession _session;
  final List<_StartCall> calls = <_StartCall>[];

  @override
  Future<StudySession> call({
    required String deckId,
    required SessionScope scope,
    required SessionType type,
    Object? selectedMode,
    List<String> relearnCardIds = const <String>[],
  }) async {
    calls.add(_StartCall(deckId, scope, type));
    return _session;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingStart implements StartStudySessionUseCase {
  @override
  Future<StudySession> call({
    required String deckId,
    required SessionScope scope,
    required SessionType type,
    Object? selectedMode,
    List<String> relearnCardIds = const <String>[],
  }) async {
    throw ValidationFailure(field: 'deckId', code: 'no-eligible-cards');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSessions implements StudySessionRepository {
  _FakeSessions(this._active);

  final StudySession? _active;

  @override
  Stream<StudySession?> watchActive() => Stream<StudySession?>.value(_active);

  @override
  Future<StudySession?> activeSession() async => _active;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDecks implements DeckRepository {
  _FakeDecks(this._roots);

  final List<Deck> _roots;

  @override
  Stream<List<Deck>> watchRoots(String languagePairId) =>
      Stream<List<Deck>>.value(_roots);

  @override
  Future<Deck?> findById(String id) async =>
      _roots.where((deck) => deck.id == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgress implements LearningProgressRepository {
  _FakeProgress(this._dueByDeck);

  final Map<String, int> _dueByDeck;

  @override
  Future<StudyQueueCounts> countDeckQueues(
    String deckId, {
    required DateTime nowUtc,
  }) async => StudyQueueCounts(dueCount: _dueByDeck[deckId] ?? 0, newCount: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPairs implements SelectLanguagePairUseCase {
  _StubPairs(this._pair);

  final LanguagePair? _pair;

  @override
  Future<LanguagePair?> activePair() async => _pair;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}
