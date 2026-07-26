/// Whether a deck's progress may be reset right now
/// (`reset-deck-progress.md` §5, §10).
///
/// A reset rewrites the SRS state of a whole subtree. A running session read
/// its cards at start and schedules against that state when it finalizes, so a
/// reset underneath it would change the queue it is working through without
/// the learner ever being told. §5 gives two ways out — block the reset, or
/// require the session to end first — and this is the first.
enum ResetProgressAvailability {
  available,

  /// A session is running over cards the reset would touch.
  blockedByActiveSession,
}
