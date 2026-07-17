/* MemoX — Game: Match. States: playing · selected · correct · wrong · almost · complete
   Feature-local component: components/Tile.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton } = NS;
const { Tile } = window.MemoXMatchMode;

const LEFT = ['time', 'love', 'friend', 'food', 'school'];
const RIGHT = ['사랑', '학교', '음식', '시간', '친구'];

function toneFor(state, side, i) {
  if (state === 'selected') return side === 'L' && i === 1 ? 'selected' : undefined;
  if (state === 'correct') return (side === 'L' && i === 1) || (side === 'R' && i === 0) ? 'correct' : undefined;
  if (state === 'wrong') return (side === 'L' && i === 1) || (side === 'R' && i === 1) ? 'wrong' : undefined;
  if (state === 'almost') {
    const matched = side === 'L' ? [0, 3, 4] : [0, 2, 3];
    return matched.includes(i) ? 'matched' : undefined;
  }
  return undefined;
}

const DONE = { playing: 0, selected: 0, correct: 4, wrong: 0, almost: 12, complete: 20 }; const TOTAL = 20;

function MatchMode({ state = 'playing' }) {
  const bar = (
    <MxContextualAppBar variant="nested" node="match-mode/appbar" title="Match"
      leading={<MxIconButton icon="arrow_back" node="match-mode/back" />}
      actions={<MxIconButton icon="more_vert" node="match-mode/options" />} />
  );

  if (state === 'complete') {
    return (
      <MxScaffold node="match-mode/screen" appBar={bar}>
        <window.ProgressHeader done={20} total={20} node="match-mode/progress" />
        <window.EmptyState node="match-mode/complete" icon="celebration" tone="success" title="Round complete!"
          text="You matched 5/5 pairs. Keep the momentum."
          action={<MxButton variant="primary" icon="arrow_forward" node="match-mode/next">Next round</MxButton>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="match-mode/screen" appBar={bar}>
      <window.ProgressHeader done={DONE[state] || 0} total={TOTAL} node="match-mode/progress" />
      {/* A tight, chunky "game board" (big cards, small 8px gaps). TOP-ALIGNED so the gap from
          the progress bar (the body's 24px) matches the other card games (MC / Recall / Fill) —
          the content lands in the same spot when switching screens, no jarring jump. The tall
          cards + the reclaimed bottom-nav padding (this screen has no bottom nav) let the board
          fill down to near the bottom, so top-aligning no longer leaves dead space. */}
      <div style={{ marginBottom: 'calc(-1 * var(--memox-bottom-nav-height))', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-2)' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
          {LEFT.map((t, i) => <Tile key={i} text={t} tone={toneFor(state, 'L', i)} node={'match-mode/left-' + i} />)}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
          {RIGHT.map((t, i) => <Tile key={i} text={t} tone={toneFor(state, 'R', i)} node={'match-mode/right-' + i} />)}
        </div>
      </div>
    </MxScaffold>
  );
}

window.MatchMode = MatchMode;
})();
