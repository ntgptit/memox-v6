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
}
