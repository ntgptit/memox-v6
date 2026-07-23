import 'dart:convert';

import 'package:memox_v6/data/database/app_database.dart';

/// Data preconditions for kit visual-parity states (WBS P0.3).
///
/// A parity fixture seeds **data only** — never flow position. The
/// Playwright spec still traverses the owning business Master flow
/// (`docs/business/**` §3) from its entry node to reach the state under
/// test; seeding the arrival point would hide exactly the navigation,
/// guard and handoff defects the E2E gate exists to catch
/// (WBS §6.6).
///
/// Ids are literal and stable so a rendered state is byte-reproducible
/// across runs; timestamps come from [fixedInstantMs] rather than a
/// real clock.
class ParityFixtures {
  ParityFixtures(this._database);

  final AppDatabase _database;

  /// The instant every parity fixture pins (2026-07-19T00:30:00Z).
  static const int fixedInstantMs = 1752885000000;

  static const String _activePairPreferenceKey = 'activeLanguagePairId';

  /// Every fixture this registry can seed, keyed by the id the parity
  /// entrypoint reads from `?fixture=`.
  static const List<String> ids = <String>[
    'MX-VIS-001',
    'MX-VIS-004',
    'MX-VIS-005',
    'MX-VIS-009',
    'MX-VIS-010',
    'MX-VIS-011',
    'MX-VIS-012',
    'MX-VIS-014',
    'MX-VIS-015',
    'MX-VIS-018',
    'MX-VIS-049',
    'MX-VIS-050',
    'MX-VIS-051',
    'MX-VIS-052',
    'MX-VIS-053',
  ];

  /// Seeds [id] over a reset database.
  ///
  /// Data only. States that also need a failing dependency get it from
  /// `app/dev/parity_overrides.dart`, which is where providers live.
  ///
  /// Throws [ArgumentError] on an unknown id so a typo in a spec fails
  /// the run loudly instead of silently rendering the wrong state.
  Future<void> seed(String id) async {
    await _reset();
    switch (id) {
      // Every first-run wizard state starts from a true fresh install; the
      // Playwright spec walks the wizard itself to reach the step under
      // test, so these need no seed beyond the reset above.
      case 'MX-VIS-001':
      case 'MX-VIS-004':
      case 'MX-VIS-005':
      case 'MX-VIS-009':
      case 'MX-VIS-010':
      case 'MX-VIS-011':
      case 'MX-VIS-012':
      case 'MX-VIS-014':
      case 'MX-VIS-015':
        return;
      case 'MX-VIS-018':
        await _seedActivePair();
        return;
      case 'MX-VIS-050':
        await _seedActiveReviewSession();
        return;
      case 'MX-VIS-051':
        await _seedActiveGuessSession();
        return;
      case 'MX-VIS-052':
        await _seedActiveRecallSession();
        return;
      case 'MX-VIS-053':
        await _seedActiveFillSession();
        return;
      case 'MX-VIS-049':
        // The Card Editor journey starts at a true fresh install. The
        // Playwright spec creates the Language Pair and Deck through the
        // production first-run UI before entering the Flashcard flow.
        return;
      default:
        throw ArgumentError.value(id, 'id', 'Unknown parity fixture');
    }
  }

  /// Fresh install: every table empty, so the first-run gate fires.
  Future<void> _reset() {
    return _database.transaction(() async {
      const tablesInDeleteOrder = <String>[
        'session_relearn_items',
        'study_round_orders',
        'study_checkpoints',
        'study_session_cards',
        'study_attempts',
        'study_sessions',
        'learning_progress',
        'card_audio_refs',
        'flashcard_tags',
        'tags',
        'flashcard_translations',
        'flashcards',
        'decks',
        'language_pairs',
        'preferences',
        'goal_day_progress',
        'daily_goals',
        'streak_days',
      ];
      for (final table in tablesInDeleteOrder) {
        await _database.customStatement('DELETE FROM $table');
      }
    });
  }

  /// The kit's canonical English -> Vietnamese pair, made active so the
  /// first-run gate stays closed and Library is the entry surface.
  Future<void> _seedActivePair({
    String learningLanguageCode = 'en',
    String meaningLanguageCode = 'vi',
  }) async {
    await _database.languagePairDao.insertLanguagePair(
      'fx-lp-1',
      learningLanguageCode,
      meaningLanguageCode,
      '$learningLanguageCode|$meaningLanguageCode',
      fixedInstantMs,
      fixedInstantMs,
    );
    await _database.preferenceDao.upsertPreference(
      _activePairPreferenceKey,
      '"fx-lp-1"',
      1,
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Review, stage 0, card 1/5 — the
  /// kit `review-mode--browsing` state (WBS 5.6.5). The first card in the
  /// persisted round order is the shot's `학교` / `school`. Seeded as data (the
  /// session, its five card snapshots and the round order) so navigating to the
  /// study route resumes into Review without a start flow.
  Future<void> _seedActiveReviewSession() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-rv-deck',
      'fx-lp-1',
      null,
      'Nouns',
      'nouns',
      fixedInstantMs,
      fixedInstantMs,
    );

    const cards = <(String, String, String)>[
      ('fx-rv-c0', '학교', 'school'),
      ('fx-rv-c1', '선생님', 'teacher'),
      ('fx-rv-c2', '학생', 'student'),
      ('fx-rv-c3', '책', 'book'),
      ('fx-rv-c4', '연필', 'pencil'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-rv-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-rv-session',
      'newLearning',
      'fx-rv-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-rv-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-rv-order',
      'fx-rv-session',
      1,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Guess, stage 2 (Review → Match →
  /// Guess), card 1/5 — the kit `guess-mode--waiting` state (WBS 5.6.7). The
  /// current card is the shot's `학교` / `school`; the pool's four other meanings
  /// (hospital, park, restaurant, library) are the distractors. The round index
  /// (67) is chosen so the seeded distractor + option shuffles
  /// ([GuessQuestionBuilder]) reproduce the kit's exact top-to-bottom option
  /// order, isolating the visual diff to the known CJK-term cap (the Korean
  /// prompt has no bundled glyph in the offline harness, same as review-mode) and
  /// the not-yet-built edit/audio affordances. Seeded as data (session, five card
  /// snapshots, the round order and the guess-stage checkpoint) so navigating to
  /// the study route resumes into Guess without a start flow.
  Future<void> _seedActiveGuessSession() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-gs-deck',
      'fx-lp-1',
      null,
      'Places',
      'places',
      fixedInstantMs,
      fixedInstantMs,
    );

    // Card 0 is the guessed card; its meaning is the correct choice. The other
    // four supply the distractor meanings shown as options. Distractor terms are
    // never rendered in the Guess prompt, so their script is immaterial.
    const cards = <(String, String, String)>[
      ('fx-gs-c0', '학교', 'school'),
      ('fx-gs-c1', '병원', 'hospital'),
      ('fx-gs-c2', '공원', 'park'),
      ('fx-gs-c3', '식당', 'restaurant'),
      ('fx-gs-c4', '도서관', 'library'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-gs-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-gs-session',
      'newLearning',
      'fx-gs-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-gs-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // The guess round carries round index 67 (see the doc comment): the checkpoint
    // and its round order share it so the loader resolves this order for stage 2.
    const guessRoundIndex = 67;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-gs-order',
      'fx-gs-session',
      guessRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-gs-checkpoint',
      'fx-gs-session',
      2,
      guessRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Recall, stage 3 (Review → Match →
  /// Guess → Recall), card 1/5 — the kit `recall-mode` states (WBS 5.6.8). The
  /// current card is the shot's `친구` / `friend`. The spec reveals the answer
  /// (tap Show) to reach the stable `recall-mode--revealed` state before
  /// capturing, since the before-reveal countdown ticks. Seeded as data (session,
  /// five card snapshots, the round order and the recall-stage checkpoint) so
  /// navigating to the study route resumes into Recall without a start flow.
  Future<void> _seedActiveRecallSession() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-rc-deck',
      'fx-lp-1',
      null,
      'People',
      'people',
      fixedInstantMs,
      fixedInstantMs,
    );

    const cards = <(String, String, String)>[
      ('fx-rc-c0', '친구', 'friend'),
      ('fx-rc-c1', '가족', 'family'),
      ('fx-rc-c2', '이웃', 'neighbor'),
      ('fx-rc-c3', '동료', 'colleague'),
      ('fx-rc-c4', '손님', 'guest'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-rc-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-rc-session',
      'newLearning',
      'fx-rc-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-rc-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // Recall is stage index 3; its round carries a distinct session-global round
    // index. The checkpoint and its round order share it so the loader resolves
    // this order for stage 3, card 0.
    const recallRoundIndex = 4;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-rc-order',
      'fx-rc-session',
      recallRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-rc-checkpoint',
      'fx-rc-session',
      3,
      recallRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Fill, stage 4 (Review → Match →
  /// Guess → Recall → Fill), card 1/5 — the kit `fill-mode--waiting` state (WBS
  /// 5.6.9). The prompt shows the meaning `friend`; the learner types the term.
  /// The waiting state shows only Latin content (meaning + placeholder), so it is
  /// free of the CJK-term cap. Seeded as data (session, five card snapshots, the
  /// round order and the fill-stage checkpoint) so navigating to the study route
  /// resumes into Fill without a start flow.
  Future<void> _seedActiveFillSession() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-fl-deck',
      'fx-lp-1',
      null,
      'Words',
      'words',
      fixedInstantMs,
      fixedInstantMs,
    );

    // The term (typed answer) is never shown in the waiting state; the meaning is
    // the prompt. Latin content keeps the compared state renderable in the
    // offline harness.
    const cards = <(String, String, String)>[
      ('fx-fl-c0', 'chingu', 'friend'),
      ('fx-fl-c1', 'gajok', 'family'),
      ('fx-fl-c2', 'iut', 'neighbor'),
      ('fx-fl-c3', 'dongryo', 'colleague'),
      ('fx-fl-c4', 'sonnim', 'guest'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-fl-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-fl-session',
      'newLearning',
      'fx-fl-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-fl-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // Fill is stage index 4; the checkpoint and its round order share the round
    // index so the loader resolves this order for stage 4, card 0.
    const fillRoundIndex = 5;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-fl-order',
      'fx-fl-session',
      fillRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-fl-checkpoint',
      'fx-fl-session',
      4,
      fillRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }
}
