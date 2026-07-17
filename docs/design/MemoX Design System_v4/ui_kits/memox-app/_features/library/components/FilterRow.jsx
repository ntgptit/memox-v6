/* FilterRow — the compact library controls row: scope · filters · sort (§11). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;

// prefix scopes the node ids to the host screen: 'library' (root, default) or
// 'subdeck-list' (the same controls row on a deck's nested-deck list). Same anatomy
// either way — only the data-mx-node prefix differs, keeping ids screen-consistent.
function FilterRow({ active, prefix = 'library' }) {
  const { MxChip } = NS;
  return (
    <div data-mx-node={prefix + '/controls'} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-2)' }}>
      <MxChip label="All decks" node={prefix + '/scope'} />
      <div style={{ flex: 1 }} />
      <MxChip label={active ? 'Filters · 2' : 'Filters'} icon="tune" selected={active} node={prefix + '/filters'} />
      <MxChip label="A–Z" icon="swap_vert" node={prefix + '/sort'} />
    </div>
  );
}

window.MemoXLibrary = Object.assign(window.MemoXLibrary || {}, { FilterRow });
})();

export const FilterRow = (window.MemoXLibrary || {}).FilterRow;
