/* MemoX — Player (auto-play). States: playing · paused · speed · end
   Feature-local components: components/{Dots,PlayerCard}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxFab, MxButton, MxSegmentedControl } = NS;
const { Dots, PlayerCard } = window.MemoXPlayer;

function Player({ state = 'playing' }) {
  const playing = state !== 'paused';
  const bar = (
    <MxContextualAppBar variant="nested" node="player/appbar" title="TOPIK I — Vocabulary"
      leading={<MxIconButton icon="arrow_back" node="player/back" />}
      actions={<MxIconButton icon="more_vert" node="player/options" />} />
  );

  if (state === 'error') {
    return (
      <MxScaffold node="player/screen" appBar={bar}>
        <window.EmptyState node="player/error" icon="volume_off" tone="error" title="Playback failed"
          text="Couldn't load the audio for this deck. Check your connection and try again."
          action={<MxButton variant="primary" icon="refresh" node="player/retry">Try again</MxButton>} />
      </MxScaffold>
    );
  }

  if (state === 'end') {
    return (
      <MxScaffold node="player/screen" appBar={bar}>
        <window.EmptyState node="player/end" icon="library_music" tone="accent" title="All played"
          text="The player has read through every card in this deck."
          action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
            <MxButton variant="primary" icon="replay" block node="player/replay">Replay</MxButton>
            <MxButton variant="ghost" icon="close" block node="player/close">Close</MxButton>
          </div>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="player/screen" appBar={bar}>
      <Dots />
      <PlayerCard />

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 'var(--memox-space-6)' }}>
        <MxIconButton icon="skip_previous" node="player/prev" />
        <MxFab icon={playing ? 'pause' : 'play_arrow'} node="player/playpause" />
        <MxIconButton icon="skip_next" node="player/next" />
      </div>

      <div style={{ marginBottom: 'calc(-1 * var(--memox-bottom-nav-height))' }}>
        {state === 'speed' ? (
          <MxSegmentedControl value="1" onChange={() => {}} block node="player/speed-control"
            segments={[{ value: '0.75', label: '×0.75' }, { value: '1', label: '×1' }, { value: '1.5', label: '×1.5' }]} />
        ) : (
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <MxButton variant="ghost" size="sm" icon="speed" node="player/speed">×1</MxButton>
          </div>
        )}
      </div>
    </MxScaffold>
  );
}

window.Player = Player;
})();
