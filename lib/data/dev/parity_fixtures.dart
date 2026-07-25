import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/dev/parity_study_fixtures.dart';

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
  ParityFixtures(this._database) : _study = ParityStudyFixtures(_database);

  final AppDatabase _database;

  /// The resumable study-session seeds, split out for file size only.
  final ParityStudyFixtures _study;

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
    'MX-VIS-037',
    'MX-VIS-043',
    'MX-VIS-049',
    'MX-VIS-050',
    'MX-VIS-051',
    'MX-VIS-052',
    'MX-VIS-053',
    'MX-VIS-054',
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
      case 'MX-VIS-037':
        await _seedParentDeck();
        return;
      case 'MX-VIS-043':
        await _seedLeafDeck();
        return;
      case 'MX-VIS-050':
        await _seedActivePair();
        await _study.seedReviewSession();
        return;
      case 'MX-VIS-051':
        await _seedActivePair();
        await _study.seedGuessSession();
        return;
      case 'MX-VIS-052':
        await _seedActivePair();
        await _study.seedRecallSession();
        return;
      case 'MX-VIS-053':
        await _seedActivePair();
        await _study.seedFillSession();
        return;
      case 'MX-VIS-054':
        // Study Result standard: past first-run so `/study` loads; the committed
        // summary is supplied through `parity_overrides` (the finished session is
        // not an active row a resume could reach).
        await _seedActivePair();
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

  /// A root deck that owns child decks — the Parent branch behind
  /// `subdeck-list--loading` (`MX-VIS-037`). The deck is seeded as data
  /// only; the spec still walks Today → Library → the deck row to reach
  /// it. The child decks are what make the branch resolve to Parent,
  /// which is what selects the kit's deck-row loading composition.
  Future<void> _seedParentDeck() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-parent',
      'fx-lp-1',
      null,
      'Korean TOPIK I',
      'korean topik i',
      fixedInstantMs,
      fixedInstantMs,
    );
    const children = <(String, String)>[
      ('fx-child-1', 'Grammar'),
      ('fx-child-2', 'Vocabulary'),
      ('fx-child-3', 'Listening'),
      ('fx-child-4', 'Reading'),
    ];
    for (final (id, name) in children) {
      await _database.deckDao.insertDeck(
        id,
        'fx-lp-1',
        'fx-parent',
        name,
        name.toLowerCase(),
        fixedInstantMs,
        fixedInstantMs,
      );
    }
  }

  /// A root deck that owns cards and no child decks — the Leaf branch
  /// behind `flashcard-list--loading` (`MX-VIS-043`). Having no children
  /// is the load-bearing part: it is what resolves the branch to Leaf and
  /// selects the kit's card-row loading composition.
  Future<void> _seedLeafDeck() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-leaf',
      'fx-lp-1',
      null,
      'Numbers & counting',
      'numbers & counting',
      fixedInstantMs,
      fixedInstantMs,
    );
    const cards = <(String, String, String)>[
      ('fx-leaf-c0', 'one', 'một'),
      ('fx-leaf-c1', 'two', 'hai'),
      ('fx-leaf-c2', 'three', 'ba'),
      ('fx-leaf-c3', 'four', 'bốn'),
      ('fx-leaf-c4', 'five', 'năm'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-leaf',
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
  }
}
