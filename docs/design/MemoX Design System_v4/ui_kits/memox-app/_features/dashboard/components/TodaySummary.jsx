/* MemoX — Dashboard local: TodaySummary (today's time + words hero card).
   `children` is an optional CTA slot (kept for contract stability; currently
   unused — the first-run empty state renders OnboardingHero instead). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard } = NS;

function TodaySummary({ time, words, children }) {
  return (
    <MxCard variant="primary" node="dashboard/today">
      <window.SectionLabel onTint style={{ margin: 0 }}>TODAY</window.SectionLabel>
      <div style={{ display: 'flex', gap: 'var(--memox-space-7)', marginTop: 'var(--memox-space-2)' }}>
        <window.Stat size="lg" align="start" onTint n={time} l="time studied" />
        <window.Stat size="lg" align="start" onTint n={words} l="words learned" />
      </div>
      {children}
    </MxCard>
  );
}

window.MemoXDashboard = window.MemoXDashboard || {};
window.MemoXDashboard.TodaySummary = TodaySummary;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const TodaySummary = (window.MemoXDashboard || {}).TodaySummary;
