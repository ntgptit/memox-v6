/* MemoX — Study-result local: ResultHero (icon tile + title + subtitle).
   Shared by the result summary and FinalizingView. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxIconTile } = NS;

function ResultHero({ icon, tone, title, text }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-3)', paddingTop: 'var(--memox-space-4)' }}>
      <MxIconTile icon={icon} tone={tone} size="lg" />
      <div>
        <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>{title}</div>
        <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)', maxWidth: 'var(--memox-size-4xl)' }}>{text}</div>
      </div>
    </div>
  );
}

window.MemoXStudyResult = window.MemoXStudyResult || {};
window.MemoXStudyResult.ResultHero = ResultHero;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ResultHero = (window.MemoXStudyResult || {}).ResultHero;
