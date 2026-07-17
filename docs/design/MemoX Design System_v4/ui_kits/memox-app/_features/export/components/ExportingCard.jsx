/* MemoX — Export local: ExportingCard (in-progress spinner + bar). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard } = NS;

function ExportingCard() {
  // KIT-42-04: progress is a polite live region (aria-busy while running) so the reader
  // hears "Exporting…" and the completion swap. Wrapper is attribute-only — no pixel change.
  return (
    <div role="status" aria-live="polite" aria-busy="true">
    <MxCard node="export/progress" style={{ alignItems: 'center', gap: 'var(--memox-space-4)', padding: 'var(--memox-space-7)' }}>
      <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-3xl)', color: 'var(--memox-primary)' }}>sync</span>
      <div style={{ fontWeight: 'var(--memox-font-weight-bold)' }}>Exporting…</div>
      <div style={{ width: '100%' }}><window.ProgressBar value={70} height={8} node="export/bar" /></div>
    </MxCard>
    </div>
  );
}

window.MemoXExport = window.MemoXExport || {};
window.MemoXExport.ExportingCard = ExportingCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ExportingCard = (window.MemoXExport || {}).ExportingCard;
