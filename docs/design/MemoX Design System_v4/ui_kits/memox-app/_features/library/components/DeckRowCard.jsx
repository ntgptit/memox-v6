/* DeckRowCard — a deck rendered as a list row. Whether it is a root deck or a nested deck (a
   Deck with parentId set), it uses the SAME shared DeckCard anatomy: an icon tile (icon + accent
   tone), title, and a "N cards · status" meta, with a quick-study trailing. There is no separate
   "Subdeck" card — a nested deck is just a Deck one level down. (Node ids keep the frozen
   `<prefix>/subdeck-N` / `/sub-study-N` contract.) */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;

function DeckRowCard({ s, index, selected, meta, nodePrefix = 'library' }) {
  const { MxIconButton } = NS;
  const { Status } = window.MemoXLibrary;
  const body = meta || <React.Fragment>{s.cards} cards · <Status d={s} /></React.Fragment>;
  return (
    <window.DeckCard
      icon={s.icon || 'style'}
      tone={s.tone || 'accent'}
      selected={selected}
      title={s.name}
      titleWeight="var(--memox-font-weight-semibold)"
      meta={body}
      trailing={<MxIconButton icon="bolt" size="sm" node={nodePrefix + '/sub-study-' + index} ariaLabel={'Study ' + s.name} />}
      node={nodePrefix + '/subdeck-' + index}
    />
  );
}

window.MemoXLibrary = Object.assign(window.MemoXLibrary || {}, { DeckRowCard });
})();

export const DeckRowCard = (window.MemoXLibrary || {}).DeckRowCard;
