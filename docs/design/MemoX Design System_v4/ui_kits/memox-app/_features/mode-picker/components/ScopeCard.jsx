/* MemoX — Mode-picker local: ScopeCard (card-source selector that opens ScopeSheet). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxIconTile } = NS;

function ScopeCard() {
  return (
    <MxCard interactive padding="sm" node="mode-picker/scope">
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
        <MxIconTile icon="tune" tone="success" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>Card source</div>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>By schedule</div>
        </div>
        <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-tertiary)' }}>expand_more</span>
      </div>
    </MxCard>
  );
}

window.MemoXModePicker = window.MemoXModePicker || {};
window.MemoXModePicker.ScopeCard = ScopeCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ScopeCard = (window.MemoXModePicker || {}).ScopeCard;
