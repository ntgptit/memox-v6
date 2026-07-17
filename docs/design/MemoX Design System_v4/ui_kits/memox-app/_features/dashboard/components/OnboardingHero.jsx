/* MemoX — Dashboard local: OnboardingHero (first-run hero card, empty state).
   Replaces the today card when the library has no decks yet: a primary-surface
   invitation to create the first deck. `children` carries the CTA stack
   (Create a deck / Import from a file). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard } = NS;

function OnboardingHero({ icon, title, text, children }) {
  return (
    <MxCard variant="primary" node="dashboard/onboarding">
      <span style={{ width: 'var(--memox-size-sm)', height: 'var(--memox-size-sm)', borderRadius: '50%', background: 'var(--memox-primary-strong)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-md)' }}>{icon}</span>
      </span>
      <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)', marginTop: 'var(--memox-space-3)' }}>{title}</div>
      <div style={{ fontSize: 'var(--memox-font-size-sm)', opacity: 'var(--memox-opacity-label)', lineHeight: 'var(--memox-line-height-normal)', marginTop: 'var(--memox-space-1)' }}>{text}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', marginTop: 'var(--memox-space-4)' }}>{children}</div>
    </MxCard>
  );
}

window.MemoXDashboard = window.MemoXDashboard || {};
window.MemoXDashboard.OnboardingHero = OnboardingHero;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const OnboardingHero = (window.MemoXDashboard || {}).OnboardingHero;
