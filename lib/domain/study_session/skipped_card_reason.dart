/// Why a session moved past a card without asking it
/// (ST-CONTENT-CHANGE-v1 ST-CHG-005, ST-CHG-006).
///
/// The names are the decision table's own: `deletedAfterSnapshot` and
/// `hiddenAfterSnapshot`. A skip is never an outcome — the card is not graded
/// correct or wrong, it simply leaves the round.
enum SkippedCardReason { deletedAfterSnapshot, hiddenAfterSnapshot }
