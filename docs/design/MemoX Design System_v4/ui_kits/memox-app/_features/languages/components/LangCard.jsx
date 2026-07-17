/* MemoX — Languages local: LangCard (a learning/native language row in the add-pair form). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard } = NS;

function LangCard({ icon, name, sub, node }) {
  return (
    <MxCard interactive padding="sm" node={node}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
        <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-lg)', color: 'var(--memox-text-secondary)' }}>{icon}</span>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>{name}</div>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>{sub}</div>
        </div>
        <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-tertiary)' }}>expand_more</span>
      </div>
    </MxCard>
  );
}

window.MemoXLanguages = window.MemoXLanguages || {};
window.MemoXLanguages.LangCard = LangCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const LangCard = (window.MemoXLanguages || {}).LangCard;
