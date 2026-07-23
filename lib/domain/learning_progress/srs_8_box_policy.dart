/// The binary terminal grade the scheduler accepts (SRS Policy v1 §1). Study
/// Session aggregates a card's evidence in one review session into exactly one
/// of these; the engine never sees per-mode outcomes.
enum SrsGrade { correct, wrong }

/// A pure scheduling decision: the resulting SRS box and its due instant. Box 8
/// (mastered) and Box 0 (pre-SRS) carry no due date.
class SrsScheduleDecision {
  const SrsScheduleDecision({required this.box, required this.dueAt});

  final int box;
  final DateTime? dueAt;
}

/// Leitner 8-box scheduling policy (WBS 5.4.3, `leitner-8-box-v1`).
///
/// The sole pure-domain SRS scheduler: given a card's current box, a terminal
/// grade and an injected `nowUtc`, it returns the next box and due instant. It
/// imports no Flutter/Drift/Riverpod, reads no clock, and mutates nothing —
/// the caller persists the result and applies counters (SRS Policy v1 §8).
///
/// Every transition is the executable contract in
/// `docs/decision-tables/srs-8-box-v1.md` (SRS8-001, 003–009, 017–024): a
/// `correct` grade promotes one box (ceiling Box 8), a `wrong` grade demotes
/// one box (sticky floor Box 1), and the resulting box's fixed interval sets
/// the due date. Reset (SRS8-016), checkpoint (SRS8-002), idempotency and
/// policy-id validation are owned by the lifecycle and transaction layers, not
/// this pure function.
class Srs8BoxPolicy {
  const Srs8BoxPolicy();

  /// Persisted identity of this policy (SRS Policy v1 §1); a future policy
  /// requires a new id, mapping and migration — never in-place reinterpretation.
  static const String policyId = 'leitner-8-box-v1';

  /// Pre-SRS state: a new card that has not completed the five-mode pipeline.
  static const int newBox = 0;

  /// First SRS box; also the sticky floor a `wrong` grade cannot fall below.
  static const int firstBox = 1;

  /// Mastered box: promoted out of every study queue, no further scheduling.
  static const int masteredBox = 8;

  /// Fixed interval in days for landing in box 1..7 (SRS Policy v1 §2):
  /// `1 · 3 · 7 · 14 · 30 · 60 · 120`. Indexed by `box - 1`.
  static const List<int> _intervalDays = <int>[1, 3, 7, 14, 30, 60, 120];

  /// Activate a completed new card: Box 0 → Box 1, due in one day (SRS8-001).
  ///
  /// The policy does not judge pipeline completeness — the caller only invokes
  /// this once Study Session emits the terminal activation outcome.
  SrsScheduleDecision activate({required DateTime nowUtc}) {
    return SrsScheduleDecision(box: firstBox, dueAt: _dueFor(firstBox, nowUtc));
  }

  /// Apply a terminal grade to an activated card in Box 1..8 (SRS8-003–009,
  /// 017–024): `correct` promotes one box (ceiling [masteredBox]), `wrong`
  /// demotes one box (floor [firstBox]); the resulting box's interval sets due.
  ///
  /// Box 0 (pre-SRS) and out-of-range boxes are caller contract violations —
  /// §5 scopes the transition formula to activated cards only.
  SrsScheduleDecision applyGrade({
    required int currentBox,
    required SrsGrade grade,
    required DateTime nowUtc,
  }) {
    if (currentBox < firstBox || currentBox > masteredBox) {
      throw ArgumentError.value(
        currentBox,
        'currentBox',
        'a terminal grade applies only to an activated card (Box '
            '$firstBox..$masteredBox)',
      );
    }
    final nextBox = grade == SrsGrade.correct
        ? (currentBox >= masteredBox ? masteredBox : currentBox + 1)
        : (currentBox <= firstBox ? firstBox : currentBox - 1);
    return SrsScheduleDecision(box: nextBox, dueAt: _dueFor(nextBox, nowUtc));
  }

  DateTime? _dueFor(int box, DateTime nowUtc) {
    if (box == masteredBox) return null;
    return nowUtc.add(Duration(days: _intervalDays[box - 1]));
  }
}
