/* Shared: DeckMoveSheet — pick a destination for the current deck. Deck-level only. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton, MxIconButton } = NS;

function DeckMoveSheet() {
  const { Scrim, Sheet, ListRow } = window;
  // The current deck shows as a short muted "This deck" row (can't move into itself); a long
  // deck name here would clip on a narrow device at large font.
  const DEST = [
    { icon: 'home', name: 'Library (root)', node: 'deck-settings/move-root' },
    { icon: 'stacks', name: 'TOPIK Prep', node: 'deck-settings/move-1' },
    { icon: 'stacks', name: 'This deck', muted: true, node: 'deck-settings/move-self' },
  ];
  return (
    <Scrim node="deck-settings/move-scrim">
      <Sheet title="Move to" node="deck-settings/move-sheet">
        {DEST.map((d) => (
          <ListRow key={d.node} icon={d.icon} title={d.name} muted={d.muted} node={d.node}
            trailing={d.muted ? null : <MxIconButton icon="radio_button_unchecked" node={d.node + '-pick'} ariaLabel={'Move to ' + d.name} />} />
        ))}
        <div style={{ marginTop: 'var(--memox-space-2)' }}><MxButton variant="primary" block node="deck-settings/move-apply">Move</MxButton></div>
      </Sheet>
    </Scrim>
  );
}
window.DeckMoveSheet = DeckMoveSheet;
})();

export const DeckMoveSheet = window.DeckMoveSheet;
