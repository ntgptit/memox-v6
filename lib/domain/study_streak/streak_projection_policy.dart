/// A local calendar date — `metrics-v1`'s `localDayId`, formatted `YYYY-MM-DD`.
///
/// Distinct from [StreakDay] in `streak_day.dart`, which is the stored record
/// (id, timezone, source). This is the date value the policy reasons over.
///
/// Deliberately not a `DateTime`: the boundary spec
/// (`handle-streak-boundary.md`) forbids deriving days from elapsed 24-hour
/// spans, and an instant invites exactly that. The record is the *date* the
/// activity belonged to in the timezone it happened in, which the recorder
/// resolves once and stores.
class LocalDay implements Comparable<LocalDay> {
  const LocalDay(this.year, this.month, this.day);

  /// The local date of [instant] in whatever zone it is already expressed in.
  /// Callers hold the timezone; this only drops the time-of-day.
  factory LocalDay.of(DateTime instant) =>
      LocalDay(instant.year, instant.month, instant.day);

  final int year;
  final int month;
  final int day;

  /// The next calendar day. `DateTime` does the month/year rollover, and
  /// because both sides are built at noon UTC a DST shift cannot move the
  /// result onto a neighbouring date.
  LocalDay get next {
    final moved = DateTime.utc(
      year,
      month,
      day,
      12,
    ).add(const Duration(days: 1));
    return LocalDay(moved.year, moved.month, moved.day);
  }

  int get _ordinal => year * 10000 + month * 100 + day;

  @override
  int compareTo(LocalDay other) => _ordinal.compareTo(other._ordinal);

  bool operator <(LocalDay other) => _ordinal < other._ordinal;
  bool operator >(LocalDay other) => _ordinal > other._ordinal;

  @override
  bool operator ==(Object other) =>
      other is LocalDay && other._ordinal == _ordinal;

  @override
  int get hashCode => _ordinal;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// A record the projection refused to count (`calculate-current-streak.md` §4:
/// "future invalid records bị loại và báo reconciliation issue").
///
/// Returned rather than thrown: one bad row must not deny the user the streak
/// their other days earned, and `reconcile-streak-history.md` owns the repair.
class StreakReconciliationIssue {
  const StreakReconciliationIssue({required this.day, required this.reason});

  final LocalDay day;
  final String reason;

  @override
  String toString() => '$day: $reason';
}

/// The read-only streak projection (`calculate-current-streak.md` §3).
class StreakProjection {
  const StreakProjection({
    required this.current,
    required this.longest,
    required this.lastQualifiedDay,
    required this.formulaVersion,
    this.issues = const <StreakReconciliationIssue>[],
  });

  /// Consecutive qualified days ending at the effective day, or within
  /// [StreakProjectionPolicy.graceDays] of it. Zero once the run is broken.
  final int current;

  /// The longest run anywhere in history. Never reduced by a broken current
  /// run (§6: "broken current không xóa longest").
  final int longest;

  /// The most recent qualified day, or null when there is no history. Explains
  /// the current state without exposing the mutable source.
  final LocalDay? lastQualifiedDay;

  /// Lets a stored projection be identified and rebuilt when the rules change.
  final int formulaVersion;

  final List<StreakReconciliationIssue> issues;
}

/// Derives current/longest streak from qualified-day records
/// (`calculate-current-streak.md`).
///
/// Pure: the same records at the same effective day always give the same
/// answer, and reading never mutates the records (§1).
class StreakProjectionPolicy {
  const StreakProjectionPolicy();

  /// Bump when the rules below change, so a stored projection can be told
  /// apart from one built by an older formula.
  static const int formulaVersion = 1;

  /// How far past the last qualified day the current run survives.
  ///
  /// `metrics-v1` settles this: "`currentStreak` is consecutive qualified
  /// local-day ids ending today, **or ending yesterday when today has no
  /// qualifying event yet**. A gap before yesterday yields zero."
  ///
  /// `calculate-current-streak.md` §1 only defers to "grace policy đã chốt"
  /// without a length, which is why this looked unspecified at first; the
  /// number lives in the statistics formulas, one directory over.
  static const int graceDays = 1;

  /// [days] may repeat, arrive unsorted, or contain dates after
  /// [effectiveDay]; all three are handled rather than rejected (§5).
  StreakProjection project({
    required Iterable<LocalDay> days,
    required LocalDay effectiveDay,
  }) {
    final issues = <StreakReconciliationIssue>[];
    final qualified = <LocalDay>{};

    for (final day in days) {
      // A record dated after the effective day cannot have happened yet. It is
      // dropped from the calculation *and* reported, because silently ignoring
      // it would leave a user whose clock rolled back with a streak that never
      // explains itself.
      if (day > effectiveDay) {
        issues.add(
          StreakReconciliationIssue(
            day: day,
            reason: 'dated after the effective day $effectiveDay',
          ),
        );
        continue;
      }
      // Same-day repeats collapse here: one local day contributes at most one
      // streak day (`study-streak/README.md`).
      qualified.add(day);
    }

    if (qualified.isEmpty) {
      return StreakProjection(
        current: 0,
        longest: 0,
        lastQualifiedDay: null,
        formulaVersion: formulaVersion,
        issues: issues,
      );
    }

    final ordered = qualified.toList()..sort();

    // Walk the ordered days once, closing a run wherever the next day is not
    // the calendar successor. Counting calendar successors rather than elapsed
    // time is the rule DST would otherwise break (§6).
    var longest = 1;
    var run = 1;
    for (var i = 1; i < ordered.length; i++) {
      run = ordered[i - 1].next == ordered[i] ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    final last = ordered.last;
    var graceEdge = last;
    for (var i = 0; i < graceDays; i++) {
      graceEdge = graceEdge.next;
    }

    // `run` is the run the last day sits in; it is the current run only while
    // the effective day has not outlived the grace window.
    final current = effectiveDay > graceEdge ? 0 : run;

    return StreakProjection(
      current: current,
      longest: longest,
      lastQualifiedDay: last,
      formulaVersion: formulaVersion,
      issues: issues,
    );
  }
}
