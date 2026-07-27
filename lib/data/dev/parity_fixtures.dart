import 'package:memox_v6/core/time/app_time_zone.dart';
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

  /// The instant every parity fixture pins (2025-07-19T00:30:00Z). The
  /// comment here read 2026 until 2026-07-26; the epoch value never moved.
  static const int fixedInstantMs = 1752885000000;

  /// The zone every parity fixture pins.
  ///
  /// A fixed offset rather than the host's: a day-keyed record seeded against
  /// one local date and read back against another is a machine-dependent
  /// failure, not a state under test.
  ///
  /// `-06:00` puts the pinned instant at 18:30 local — evening, which is the
  /// greeting the kit's dashboard shots were taken in. The offset is chosen
  /// to reproduce the reference, the same way the instant itself is.
  static const AppTimeZone fixedZone = FixedOffsetTimeZone(
    id: 'UTC-06',
    offset: Duration(hours: -6),
  );

  /// The local day [fixedInstantMs] falls in under [fixedZone].
  static const String fixedLocalDate = '2025-07-18';

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
    'MX-VIS-034',
    'MX-VIS-036',
    'MX-VIS-037',
    'MX-VIS-043',
    'MX-VIS-049',
    'MX-VIS-055',
    'MX-VIS-056',
    'MX-VIS-057',
    'MX-VIS-058',
    'MX-VIS-059',
    'MX-VIS-060',
    'MX-VIS-050',
    'MX-VIS-062',
    'MX-VIS-063',
    'MX-VIS-064',
    'MX-VIS-065',
    'MX-VIS-066',
    'MX-VIS-067',
    'MX-VIS-038',
    'MX-VIS-044',
    'MX-VIS-051',
    'MX-VIS-052',
    'MX-VIS-053',
    'MX-VIS-054',
    'MX-VIS-077',
    'MX-VIS-080',
    'MX-VIS-078',
    'MX-VIS-079',
    'MX-VIS-069',
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
      case 'MX-VIS-034':
        await _seedEmptyDeck();
        return;
      case 'MX-VIS-036':
        await _seedLoadedParentDeck();
        return;
      case 'MX-VIS-037':
      // The failure states need the same data as the loading ones: the deck
      // resolves, and only the child read breaks.
      case 'MX-VIS-038':
        await _seedParentDeck();
        return;
      case 'MX-VIS-043':
      case 'MX-VIS-044':
        await _seedLeafDeck();
        return;
      case 'MX-VIS-062':
      case 'MX-VIS-063':
      case 'MX-VIS-064':
      case 'MX-VIS-065':
      // 066 (`almost`) and 067 (`complete`) are the same board reached
      // further in: the kit's `almost` is *almost finished*, not "almost
      // correct" — `MatchMode.jsx` tones three tiles a side `matched` and
      // shows 12/20. Both are journeys over this fixture, not new data.
      case 'MX-VIS-066':
      case 'MX-VIS-067':
        await _seedActivePair();
        await _study.seedMatchSession();
        return;
      case 'MX-VIS-079':
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
      case 'MX-VIS-078':
        await _seedActivePair();
        await _study.seedFillSessionAtShotPosition();
        return;
      case 'MX-VIS-053':
        await _seedActivePair();
        await _study.seedFillSession();
        return;
      case 'MX-VIS-080':
      case 'MX-VIS-077':
      case 'MX-VIS-054':
        // Study Result standard: past first-run so `/study` loads; the committed
        // summary is supplied through `parity_overrides` (the finished session is
        // not an active row a resume could reach).
        await _seedActivePair();
        return;
      case 'MX-VIS-069':
        await _seedLoadedDashboard();
        return;
      case 'MX-VIS-049':
      case 'MX-VIS-055':
      case 'MX-VIS-056':
      case 'MX-VIS-057':
      case 'MX-VIS-058':
      case 'MX-VIS-059':
      case 'MX-VIS-060':
        // The Card Editor journeys start at a true fresh install. The
        // Playwright spec creates the Language Pair and Deck through the
        // production first-run UI before entering the Flashcard flow.
        //
        // `MX-VIS-055` (duplicate) seeds nothing either, deliberately: a
        // duplicate is by definition a *second* card carrying a term the
        // deck already holds, so the spec saves the first card through the
        // real create path and then re-enters the editor with the same term.
        // Seeding the existing card instead would skip the write path the
        // detector reads from.
        return;
      default:
        throw ArgumentError.value(id, 'id', 'Unknown parity fixture');
    }
  }

  /// The kit `dashboard--loaded` scope: three decks carrying the shot's
  /// counts, a live streak, and a daily goal partway through.
  ///
  /// The shot's header reads `24 cards due across 3 decks`, so the deck due
  /// counts sum to 24 and there are exactly three of them. Their mastered
  /// share is seeded to the shot's `55% library mastered` — 55 of 100
  /// studiable cards — so the strip's number comes from the data rather than
  /// from a constant beside it.
  Future<void> _seedLoadedDashboard() async {
    await _seedActivePair();

    // (id, name, cards, due, mastered) — ordered as the kit lists them, which
    // is most-recently-studied first. Cards total 100 and mastered total 55.
    const decks = <(String, String, int, int, int)>[
      ('fx-d1', 'TOPIK I — Vocabulary', 40, 15, 22),
      ('fx-d2', 'Basic Grammar', 35, 6, 20),
      ('fx-d3', 'Daily Conversation', 25, 3, 13),
    ];
    // Each deck's most recent grade, newest first, so the section order is
    // the query's answer rather than an insertion accident.
    const lastReviewedOffsets = <int>[1000, 2000, 3000];

    for (var deckIndex = 0; deckIndex < decks.length; deckIndex += 1) {
      final (deckId, name, cards, due, mastered) = decks[deckIndex];
      await _database.deckDao.insertDeck(
        deckId,
        'fx-lp-1',
        null,
        name,
        name.toLowerCase(),
        fixedInstantMs,
        fixedInstantMs,
      );
      for (var index = 0; index < cards; index += 1) {
        final cardId = '$deckId-c$index';
        await _database.flashcardDao.insertFlashcard(
          cardId,
          deckId,
          'term-$cardId',
          'term-$cardId',
          'meaning-$cardId',
          fixedInstantMs,
          fixedInstantMs,
        );
        final isDue = index < due;
        final isMastered = !isDue && index < due + mastered;
        await _database.learningProgressDao.insertProgress(
          'p-$cardId',
          cardId,
          isDue ? 1 : (isMastered ? 8 : 0),
          isDue ? fixedInstantMs - 1 : null,
          fixedInstantMs,
          fixedInstantMs,
        );
      }
      // One graded card per deck carries the deck's last-studied instant.
      await _database.customStatement(
        'UPDATE learning_progress SET last_reviewed_at = ? WHERE card_id = ?',
        <Object?>[
          fixedInstantMs - lastReviewedOffsets[deckIndex],
          '$deckId-c0',
        ],
      );
    }

    await _seedStreak(days: 12);
    await _seedGoal(target: 20, done: 14);
  }

  /// [days] consecutive qualified days ending on [fixedLocalDate], so the
  /// projection reads a live streak of exactly that length.
  Future<void> _seedStreak({required int days}) async {
    var day = DateTime.utc(2025, 7, 18).subtract(Duration(days: days - 1));
    for (var index = 0; index < days; index += 1) {
      final localDate =
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      await _database.streakDao.recordStreakDay(
        'fx-streak-$index',
        localDate,
        fixedZone.id,
        'seed',
        fixedInstantMs,
      );
      day = day.add(const Duration(days: 1));
    }
  }

  /// A configured goal and today's bucket, so the card renders partway
  /// through rather than absent.
  Future<void> _seedGoal({required int target, required int done}) async {
    await _database.studyGoalDao.insertGoal(
      'fx-goal',
      // The schema stores these flags as integers.
      1,
      target,
      fixedLocalDate,
      fixedZone.id,
      fixedInstantMs,
      fixedInstantMs,
    );
    await _database.studyGoalDao.upsertDayProgress(
      'fx-goal-day',
      fixedLocalDate,
      fixedZone.id,
      'fx-goal',
      done,
      target,
      done >= target ? 1 : 0,
      fixedInstantMs,
      fixedInstantMs,
    );
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

  /// The kit `subdeck-list--loaded` scope: a parent whose five children
  /// carry the shot's exact counts. Their card totals sum to the header's
  /// `217 cards` and their due counts to `23 due`, so the aggregate line is
  /// reproduced by the data rather than asserted separately.
  Future<void> _seedLoadedParentDeck() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-loaded',
      'fx-lp-1',
      null,
      'Korean TOPIK I',
      'korean topik i',
      fixedInstantMs,
      fixedInstantMs,
    );
    // (id, name, cards, due, new) — ordered as the kit lists them. The
    // repository orders children by normalized name, so each id is prefixed
    // to hold the shot's order.
    const children = <(String, String, int, int, int)>[
      ('fx-l1', 'Greetings & introductions', 42, 8, 0),
      ('fx-l2', 'Numbers & counting', 55, 0, 0),
      ('fx-l3', 'Family & relationships', 38, 0, 6),
      ('fx-l4', 'Food & dining', 47, 15, 0),
      ('fx-l5', 'Directions & transport', 35, 0, 0),
    ];
    for (final (deckId, name, cards, due, fresh) in children) {
      await _database.deckDao.insertDeck(
        deckId,
        'fx-lp-1',
        'fx-loaded',
        name,
        '$deckId $name'.toLowerCase(),
        fixedInstantMs,
        fixedInstantMs,
      );
      for (var index = 0; index < cards; index += 1) {
        final cardId = '$deckId-c$index';
        await _database.flashcardDao.insertFlashcard(
          cardId,
          deckId,
          'term-$cardId',
          'term-$cardId',
          'meaning-$cardId',
          fixedInstantMs,
          fixedInstantMs,
        );
        // Box 1..7 with a past due date reads as due; box 0 reads as new;
        // box 8 is mastered and sits in neither queue, which is what makes
        // a deck show `Up to date`.
        final isDue = index < due;
        final isNew = !isDue && index < due + fresh;
        await _database.learningProgressDao.insertProgress(
          'p-$cardId',
          cardId,
          isDue ? 1 : (isNew ? 0 : 8),
          isDue ? fixedInstantMs - 1 : null,
          fixedInstantMs,
          fixedInstantMs,
        );
      }
    }
  }

  /// A root deck that owns cards and no child decks — the Leaf branch
  /// behind `flashcard-list--loading` (`MX-VIS-043`). Having no children
  /// is the load-bearing part: it is what resolves the branch to Leaf and
  /// selects the kit's card-row loading composition.
  /// An active pair and one deck holding nothing at all — the content-choice
  /// state, where a deck has not yet become a Leaf or a Parent.
  Future<void> _seedEmptyDeck() async {
    await _seedActivePair();
    await _database.deckDao.insertDeck(
      'fx-empty',
      'fx-lp-1',
      null,
      'Numbers & counting',
      'numbers & counting',
      fixedInstantMs,
      fixedInstantMs,
    );
  }

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
