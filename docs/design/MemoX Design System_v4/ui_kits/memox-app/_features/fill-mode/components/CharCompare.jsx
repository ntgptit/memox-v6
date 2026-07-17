/* MemoX — Game-typing local: CharCompare (per-character typed-vs-correct diff). */
(function () {

function CharCompare() {
  const typed = ['친', '고'];
  const correct = ['친', '구'];
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--memox-space-1) var(--memox-space-2)', justifyContent: 'center' }}>
      {correct.map((c, i) => {
        const ok = typed[i] === c;
        return <span key={i} style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-extrabold)', color: ok ? 'var(--memox-success)' : 'var(--memox-error)' }}>{typed[i] || '_'}</span>;
      })}
    </div>
  );
}

window.MemoXFillMode = window.MemoXFillMode || {};
window.MemoXFillMode.CharCompare = CharCompare;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const CharCompare = (window.MemoXFillMode || {}).CharCompare;
