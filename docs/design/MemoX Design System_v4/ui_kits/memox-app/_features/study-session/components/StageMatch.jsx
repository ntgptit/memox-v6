/* MemoX — Study-session local: StageMatch (stage 2 — two columns of tiles).
   `Tile` is used only here, so it stays inside this file. It is a plain styled
   div — no Mx* primitive needed, so this file intentionally reads no NS. */
(function () {

function Tile({ text }) {
  return <div style={{ border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', background: 'var(--memox-surface)', borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-4) var(--memox-space-2)', textAlign: 'center', fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>{text}</div>;
}

function StageMatch() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>{['school', 'love', 'friend'].map((t) => <Tile key={t} text={t} />)}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>{['사랑', '친구', '학교'].map((t) => <Tile key={t} text={t} />)}</div>
    </div>
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.StageMatch = StageMatch;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const StageMatch = (window.MemoXStudySession || {}).StageMatch;
