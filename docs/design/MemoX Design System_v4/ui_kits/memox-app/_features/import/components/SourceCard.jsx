/* MemoX — Import local: SourceCard (one import-source option in the "source" state). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxIconTile } = NS;

function SourceCard({ source, index }) {
  return (
    <MxCard interactive padding="sm" node={'import/source-' + index}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
        <MxIconTile icon={source.icon} tone={index === 2 ? 'accent' : null} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>{source.name}</div>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>{source.desc}</div>
        </div>
        <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-tertiary)' }}>chevron_right</span>
      </div>
    </MxCard>
  );
}

window.MemoXImport = window.MemoXImport || {};
window.MemoXImport.SourceCard = SourceCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const SourceCard = (window.MemoXImport || {}).SourceCard;
