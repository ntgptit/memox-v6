/* MemoX — Game-matching local: Tile (a match tile; tone tints the skin, matched hides it).
   Owns its TONE → skin map. */
(function () {

const TONE = {
  selected: { border: 'var(--memox-stroke-emphasis) solid var(--memox-primary)', background: 'var(--memox-primary-soft)', color: 'var(--memox-on-primary-soft)' },
  correct: { border: 'var(--memox-stroke-emphasis) solid var(--memox-success)', background: 'var(--memox-success-soft)', color: 'var(--memox-on-success-soft)' },
  wrong: { border: 'var(--memox-stroke-emphasis) solid var(--memox-error)', background: 'var(--memox-error-soft)', color: 'var(--memox-on-error-soft)' },
};

function Tile({ text, tone, node }) {
  if (tone === 'matched') return <div style={{ minHeight: 'calc(var(--memox-size-xl) + var(--memox-space-5))', visibility: 'hidden' }} />;
  const skin = TONE[tone] || { border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', background: 'var(--memox-surface)' };
  // The skin transitions on tone change — this is the correct-match flash the app
  // holds (var(--memox-duration-flash)) before the tile clears to 'matched'.
  const flash = 'var(--memox-duration-flash) var(--memox-ease-standard)';
  return (
    <div data-mx-node={node} style={{ ...skin, transition: `background ${flash}, border-color ${flash}, color ${flash}`, borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-4) var(--memox-space-3)', minHeight: 'calc(var(--memox-size-xl) + var(--memox-space-5))', display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)', cursor: 'pointer' }}>{text}</div>
  );
}

window.MemoXMatchMode = window.MemoXMatchMode || {};
window.MemoXMatchMode.Tile = Tile;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const Tile = (window.MemoXMatchMode || {}).Tile;
