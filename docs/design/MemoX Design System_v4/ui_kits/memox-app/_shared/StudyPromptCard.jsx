/* Shared: StudyPromptCard — the study prompt term centred in a card, with the audio (and,
   when editable, edit) controls tucked into the right corners so the term stays the sole
   focus. Used by Guess (compact, editable), Recall (fill, editable) and Review (fill,
   audio-only — its edit lives on the meaning card; `playing` swaps in the equaliser icon +
   "Playing…"). `nodePrefix` keeps each screen's data-mx-node ids: <prefix>/prompt · /edit
   · /audio. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard, MxIconButton } = NS;

function StudyPromptCard({ term, nodePrefix, fill, editable = true, playing = false }) {
  const sizing = fill ? { flex: 1 } : { minHeight: 'calc(var(--memox-size-2xl) + var(--memox-space-6))' };
  return (
    <MxCard node={nodePrefix + '/prompt'} style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: 'var(--memox-space-6)', ...sizing }}>
      <div style={{ fontSize: 'var(--memox-font-size-3xl)', fontWeight: 'var(--memox-font-weight-bold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>{term}</div>
      {editable ? (
        <div style={{ position: 'absolute', top: 'var(--memox-space-4)', right: 'var(--memox-space-4)' }}>
          <MxIconButton icon="edit" size="sm" node={nodePrefix + '/edit'} ariaLabel="Edit card" />
        </div>
      ) : null}
      <div style={{ position: 'absolute', bottom: 'var(--memox-space-4)', right: 'var(--memox-space-4)', display: 'flex', alignItems: 'center', gap: 'var(--memox-space-2)' }}>
        {playing ? <span style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-primary)', fontWeight: 'var(--memox-font-weight-semibold)' }}>Playing…</span> : null}
        <MxIconButton icon={playing ? 'graphic_eq' : 'volume_up'} node={nodePrefix + '/audio'} ariaLabel="Play pronunciation" />
      </div>
    </MxCard>
  );
}

window.StudyPromptCard = StudyPromptCard;
})();

export const StudyPromptCard = window.StudyPromptCard;
