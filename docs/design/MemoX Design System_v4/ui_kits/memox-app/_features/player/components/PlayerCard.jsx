/* MemoX — Player local: PlayerCard (current term + meaning being read aloud). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard } = NS;

function PlayerCard() {
  return (
    <MxCard node="player/card" style={{ flex: 1, alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 'var(--memox-space-4)', minHeight: 'var(--memox-size-4xl)' }}>
      <div style={{ fontSize: 'var(--memox-font-size-3xl)', fontWeight: 'var(--memox-font-weight-bold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>학교</div>
      <div style={{ width: 'var(--memox-size-md)', height: 'var(--memox-size-3xs)', background: 'var(--memox-divider)', borderRadius: 'var(--memox-radius-xs)' }} />
      <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>school</div>
    </MxCard>
  );
}

window.MemoXPlayer = window.MemoXPlayer || {};
window.MemoXPlayer.PlayerCard = PlayerCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const PlayerCard = (window.MemoXPlayer || {}).PlayerCard;
