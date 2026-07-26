import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/learning_progress/study_queue_counts.dart';

/// WBS 5.7.1 — the Today read projection composes existing sources into one
/// primary action, never recomputing them (`load-today-dashboard.md` §§1-3).
void main() {
  final now = DateTime.utc(2026, 7, 24, 10);

  DeckSummary deckNamed(String name, {int mastered = 0, int studiable = 0}) =>
      DeckSummary(
        deck: Deck(
          id: name,
          languagePairId: 'lp1',
          parentId: null,
          name: name,
          normalizedName: name.toLowerCase(),
          createdAt: now,
          updatedAt: now,
        ),
        cardCount: studiable,
        masteredCount: mastered,
        studiableCount: studiable,
      );

  LoadTodayProjectionUseCase build({
    StudySession? paused,
    LanguagePair? pair,
    int libraryCards = 5,
    int due = 0,
    _FakeDecks? decks,
    LibraryMastery? mastery,
  }) => LoadTodayProjectionUseCase(
    sessions: _FakeSessions(paused),
    decks: decks ?? _FakeDecks(libraryCards),
    languagePairs: _StubPairs(pair),
    queueCounts: LoadStudyQueueCountsUseCase(
      progress: _FakeProgress(due, mastery: mastery),
      decks: _FakeDecks(libraryCards),
      clock: _FixedClock(now),
    ),
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

  // Today scopes its library card count to the active pair, and used to count
  // due cards across the whole database. With two pairs configured it
  // advertised review work from a pair whose decks the Library does not show,
  // and the number disagreed with the scope a session would run over.
  test('the due count ignores other language pairs', () async {
    final projection = await LoadTodayProjectionUseCase(
      sessions: _FakeSessions(null),
      decks: _FakeDecks(12),
      languagePairs: _StubPairs(pair),
      queueCounts: LoadStudyQueueCountsUseCase(
        progress: _FakeProgress(3, otherPairDue: 40),
        decks: _FakeDecks(12),
        clock: _FixedClock(now),
      ),
    ).call();

    expect(projection.dueCount, 3, reason: 'lp1 only, not lp1 + the other 40');
    expect(projection.primaryAction, TodayPrimaryAction.startReview);
  });

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

  test(
    'no session with due cards starts a review, composing the count',
    () async {
      final projection = await build(
        pair: pair,
        libraryCards: 12,
        due: 7,
      ).call();
      expect(projection.primaryAction, TodayPrimaryAction.startReview);
      expect(projection.dueCount, 7);
      expect(projection.pausedSession, isNull);
    },
  );

  test('no session, cards present but none due, is caught up', () async {
    final projection = await build(pair: pair, libraryCards: 12, due: 0).call();
    expect(projection.primaryAction, TodayPrimaryAction.caughtUp);
    expect(projection.dueCount, 0);
  });

  test('no active pair is treated as an empty library', () async {
    final projection = await build(due: 0).call();
    expect(projection.primaryAction, TodayPrimaryAction.createLibrary);
  });

  // `load-today-dashboard.md` §3: Deck summaries are a supporting section of
  // Today, so the projection composes them rather than the screen fetching
  // them itself.
  test('composes the recent decks, bounded by the section limit', () async {
    final decks = _FakeDecks(
      12,
      recent: <DeckSummary>[
        deckNamed('Grammar', mastered: 9, studiable: 12),
        deckNamed('Vocabulary'),
        deckNamed('Phrases'),
        deckNamed('Listening'),
      ],
    );

    final projection = await build(pair: pair, due: 4, decks: decks).call();

    expect(decks.askedLimit, TodayProjection.recentDeckLimit);
    expect(projection.recentDecks.length, TodayProjection.recentDeckLimit);
    expect(projection.recentDecks.first.deck.name, 'Grammar');
    expect(projection.recentDecks.first.masteryFraction, 0.75);
  });

  // The strip's one always-available metric besides the streak.
  test('composes the library mastery for the active pair', () async {
    final projection = await build(
      pair: pair,
      due: 4,
      mastery: const LibraryMastery(masteredCount: 11, studiableCount: 20),
    ).call();

    expect(projection.libraryMastery.masteredCount, 11);
    expect(projection.libraryMastery.fraction, 0.55);
  });

  test('no active pair reports no mastery rather than failing', () async {
    final projection = await build(libraryCards: 0).call();

    expect(projection.libraryMastery.studiableCount, 0);
    expect(projection.libraryMastery.fraction, 0);
  });

  // No active pair means no library to read from, and the section is empty
  // rather than the load failing — it is supporting, not primary.
  test('no active pair yields no deck rows', () async {
    final projection = await build(libraryCards: 0).call();

    expect(projection.recentDecks, isEmpty);
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
  Future<StudySession?> activeSession() async => _paused;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Counts due cards **per language pair**, the way the scoped SQL does.
///
/// The unscoped `countDue` this screen used to call no longer exists on the
/// port at all, so there is nothing left to reach for by mistake.
class _FakeProgress implements LearningProgressRepository {
  _FakeProgress(this._due, {this.otherPairDue = 0, this.mastery});
  final int _due;
  final int otherPairDue;
  final LibraryMastery? mastery;

  @override
  Future<LibraryMastery> countLibraryMastery(String languagePairId) async =>
      mastery ?? const LibraryMastery.empty();

  @override
  Future<StudyQueueCounts> countLibraryQueues(
    String languagePairId, {
    required DateTime nowUtc,
  }) async => StudyQueueCounts(
    dueCount: languagePairId == 'lp1' ? _due : otherPairDue,
    newCount: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDecks implements DeckRepository {
  _FakeDecks(this._cards, {List<DeckSummary> recent = const <DeckSummary>[]})
    : _recent = recent;

  final int _cards;
  final List<DeckSummary> _recent;

  /// The limit the projection asked for, so a test can assert the section is
  /// bounded rather than trusting the caller passed something.
  int? askedLimit;

  @override
  Future<int> countForLanguagePair(String languagePairId) async => _cards;

  @override
  Future<List<DeckSummary>> recentSummaries(
    String languagePairId, {
    required int limit,
  }) async {
    askedLimit = limit;
    return _recent.take(limit).toList();
  }

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
