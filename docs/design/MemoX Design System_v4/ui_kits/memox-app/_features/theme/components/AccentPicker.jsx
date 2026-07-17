/* MemoX — Theme local: AccentPicker (accent-color swatch grid; `accent` = selected index). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard } = NS;

function AccentPicker({ swatches, accent }) {
  return (
    <MxCard>
      <div style={{ display: 'flex', gap: 'var(--memox-space-4)', flexWrap: 'wrap', justifyContent: 'center' }}>
        {swatches.map((c, i) => (
          <button key={c} data-mx-node={'theme/accent-' + i} className="accent-swatch" style={{ width: 'var(--memox-size-sm)', height: 'var(--memox-size-sm)', borderRadius: '50%', background: c, border: 'none', boxShadow: i === accent ? '0 0 0 var(--memox-stroke-focus) ' + c : '0 0 0 var(--memox-stroke-hairline) var(--memox-divider)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {i === accent ? <span className="material-symbols-rounded" style={{ color: 'var(--memox-on-primary)', fontSize: 'var(--memox-icon-size-md)' }}>check</span> : null}
          </button>
        ))}
      </div>
    </MxCard>
  );
}

window.MemoXTheme = window.MemoXTheme || {};
window.MemoXTheme.AccentPicker = AccentPicker;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const AccentPicker = (window.MemoXTheme || {}).AccentPicker;
