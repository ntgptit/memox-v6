import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';

/// WBS 5.7.1 — the Today read projection composes existing sources into one
/// primary action, never recomputing them (`load-today-dashboard.md` §§1-3).
void main() {
  final now = DateTime.utc(2026, 7, 24, 10);

  LoadTodayProjectionUseCase build({
    StudySession? paused,
    LanguagePair? pair,
    int libraryCards = 5,
    int due = 0,
  }) => LoadTodayProjectionUseCase(
    sessions: _FakeSessions(paused),
    progress: _FakeProgress(due),
    decks: _FakeDecks(libraryCards),
    languagePairs: _StubPairs(pair),
    clock: _FixedClock(now),
  );

  final pair = LanguagePair(
    id: 'lp1',
    learningLanguageCode: 'en',
    nativeLanguageCode: 'vi',
    normalizedPairKey: 'en|vi',
    createdAt: now,
    updatedAt: now,
  );

  StudySession session() => StudySession(
    id: 's1',
    type: SessionType.newLearning,
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

  test('a resumable session wins the primary action', () async {
    final projection = await build(
      paused: session(),
      pair: pair,
      due: 9,
    ).call();
    expect(projection.primaryAction, TodayPrimaryAction.continueSession);
    expect(projection.pausedSession, isNotNull);
  });

  test('no session + empty library asks to create', () async {
    final projection = await build(pair: pair, libraryCards: 0, due: 0).call();
    expect(projection.primaryAction, TodayPrimaryAction.createLibrary);
  });

  test('no session with due cards starts a review, composing the count', () async {
    final projection = await build(pair: pair, libraryCards: 12, due: 7).call();
    expect(projection.primaryAction, TodayPrimaryAction.startReview);
    expect(projection.dueCount, 7);
    expect(projection.pausedSession, isNull);
  });

  test('no session, cards present but none due, is caught up', () async {
    final projection = await build(pair: pair, libraryCards: 12, due: 0).call();
    expect(projection.primaryAction, TodayPrimaryAction.caughtUp);
    expect(projection.dueCount, 0);
  });

  test('no active pair is treated as an empty library', () async {
    final projection = await build(due: 0).call();
    expect(projection.primaryAction, TodayPrimaryAction.createLibrary);
  });
}

class _FixedClock implements AppClock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _FakeSessions implements StudySessionRepository {
  _FakeSessions(this._paused);
  final StudySession? _paused;
  @override
  Stream<StudySession?> watchActive() => Stream<StudySession?>.value(_paused);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgress implements LearningProgressRepository {
  _FakeProgress(this._due);
  final int _due;
  @override
  Future<int> countDue(DateTime nowUtc) async => _due;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDecks implements DeckRepository {
  _FakeDecks(this._cards);
  final int _cards;
  @override
  Future<int> countForLanguagePair(String languagePairId) async => _cards;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Overrides the active-pair lookup; the super dependencies are never used.
class _StubPairs extends SelectLanguagePairUseCase {
  _StubPairs(this._pair)
    : super(pairs: _Unused(), preferences: _Unused(), clock: _Unused());
  final LanguagePair? _pair;
  @override
  Future<LanguagePair?> activePair() async => _pair;
}

class _Unused
    implements LanguagePairRepository, PreferenceRepository, AppClock {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
