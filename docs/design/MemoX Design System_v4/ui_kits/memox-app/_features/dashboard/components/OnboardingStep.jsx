/* MemoX — Dashboard local: OnboardingStep (one "How MemoX works" row, empty state).
   Icon tile + title + caption on a small card — the DeckRow silhouette without
   badge/progress, so the first-run screen previews the loaded dashboard's rhythm. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxIconTile } = NS;

function OnboardingStep({ icon, tone, title, text, node }) {
  return (
    <MxCard padding="sm" node={node}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
        <MxIconTile icon={icon} tone={tone} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>{title}</div>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>{text}</div>
        </div>
      </div>
    </MxCard>
  );
}

window.MemoXDashboard = window.MemoXDashboard || {};
window.MemoXDashboard.OnboardingStep = OnboardingStep;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const OnboardingStep = (window.MemoXDashboard || {}).OnboardingStep;
