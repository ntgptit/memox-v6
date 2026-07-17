/* MemoX — Dashboard local: GoalCard (daily goal + progress ring). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard } = NS;

function GoalCard({ pct, met, minutes = 14, goal = 20 }) {
  const left = Math.max(0, goal - minutes);
  // Custom padding: 32px horizontal (VIS-021), 16px vertical. Internal spacing comes from
  // the card's own flex gap (12) — the previous marginTop stacked ON TOP of that gap
  // (12+8=20 each), inflating the card; removing it drops height ~16px without shrinking
  // any font or the progress bar.
  return (
    <MxCard node="dashboard/goal" style={{ padding: 'var(--memox-space-4) var(--memox-space-7)' }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 'var(--memox-space-3)' }}>
        <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-md)' }}>Daily goal</div>
        {/* The metric uses primary TEXT (bright in both themes) — the accent/purple lives on
            the progress bar below. Primary-tinted numerals read as dim on the dark card. */}
        <div style={{ fontWeight: 'var(--memox-font-weight-extrabold)', fontSize: 'var(--memox-font-size-lg)', color: 'var(--memox-text)' }}>{pct}%</div>
      </div>
      <window.ProgressBar value={pct} height={10} node="dashboard/goal-bar" />
      <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>
        {met ? '20 of 20 minutes · goal complete' : `${minutes} of ${goal} minutes · ${left} minutes left`}
      </div>
    </MxCard>
  );
}

window.MemoXDashboard = window.MemoXDashboard || {};
window.MemoXDashboard.GoalCard = GoalCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const GoalCard = (window.MemoXDashboard || {}).GoalCard;
