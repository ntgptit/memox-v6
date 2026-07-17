/* MemoX — Dashboard local: StreakCard (day-streak stat). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard } = NS;

function StreakCard({ streak }) {
  return (
    <MxCard variant="primary-soft" padding="sm" node="dashboard/streak">
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)' }}>
        <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-xl)' }}>local_fire_department</span>
        <window.Stat align="start" onTint n={streak} l="day streak" />
      </div>
    </MxCard>
  );
}

window.MemoXDashboard = window.MemoXDashboard || {};
window.MemoXDashboard.StreakCard = StreakCard;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const StreakCard = (window.MemoXDashboard || {}).StreakCard;
