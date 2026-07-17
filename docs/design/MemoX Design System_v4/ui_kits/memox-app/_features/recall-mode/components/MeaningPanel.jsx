/* MemoX — Game-recall local: MeaningPanel (hidden prompt → revealed meaning). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard } = NS;

function MeaningPanel({ revealed }) {
  return (
    <MxCard node="recall-mode/meaning" style={{ flex: 1, alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-2)', minHeight: 'var(--memox-size-2xl)', justifyContent: 'center' }}>
      {revealed ? (
        <React.Fragment>
          <div style={{ width: 'var(--memox-size-md)', height: 'var(--memox-size-3xs)', background: 'var(--memox-divider)', borderRadius: 'var(--memox-radius-xs)' }} />
          <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>friend</div>
          <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)' }}>a friend, companion</div>
        </React.Fragment>
      ) : (
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-2)', color: 'var(--memox-text-tertiary)', fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-semibold)' }}>
          <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-sm)' }}>visibility</span> Recall the meaning, then tap “Show”
        </div>
      )}
    </MxCard>
  );
}

window.MemoXRecallMode = window.MemoXRecallMode || {};
window.MemoXRecallMode.MeaningPanel = MeaningPanel;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const MeaningPanel = (window.MemoXRecallMode || {}).MeaningPanel;
