/* MemoX — Mode-picker local: ModeOption (one study-mode choice row). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard, MxIconTile } = NS;

function ModeOption({ g, disabled }) {
  return (
    <MxCard interactive padding="sm" node={'mode-picker/mode-' + g.id} style={{ opacity: disabled ? 'var(--memox-opacity-half)' : 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
        <MxIconTile icon={g.icon} tone="accent" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>{g.name}</div>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>{g.desc}</div>
        </div>
        <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-tertiary)' }}>chevron_right</span>
      </div>
    </MxCard>
  );
}

window.MemoXModePicker = window.MemoXModePicker || {};
window.MemoXModePicker.ModeOption = ModeOption;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const ModeOption = (window.MemoXModePicker || {}).ModeOption;
