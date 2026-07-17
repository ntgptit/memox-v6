/* MemoX — Import local: Table (2-column preview table). Used by mapping + preview. */
(function () {

function Table({ rows }) {
  return (
    <div style={{ border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', borderRadius: 'var(--memox-radius-control)', overflow: 'hidden' }}>
      {rows.map((r, i) => (
        <div key={i} style={{ display: 'flex', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderTop: i ? 'var(--memox-stroke-hairline) solid var(--memox-divider)' : 'none', background: i === 0 ? 'var(--memox-surface-sunken)' : 'transparent', fontSize: 'var(--memox-font-size-sm)' }}>
          <span style={{ flex: 1, fontWeight: 'var(--memox-font-weight-bold)' }}>{r[0]}</span>
          <span style={{ flex: 1.4, fontWeight: i === 0 ? 'var(--memox-font-weight-bold)' : 'var(--memox-font-weight-regular)', color: i === 0 ? 'inherit' : 'var(--memox-text-secondary)' }}>{r[1]}</span>
        </div>
      ))}
    </div>
  );
}

window.MemoXImport = window.MemoXImport || {};
window.MemoXImport.Table = Table;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const Table = (window.MemoXImport || {}).Table;
