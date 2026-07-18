/* MemoX — Search local: Chips (status filter chip row). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxChip } = NS;

/* Search filters along business dimensions (search/filter-search-results.md): object
   type, language pair, deck scope, visibility — NOT SRS learning status. Search does not
   index Progress content (update-search-index.md §3) — see ADR-009 / CF-14. */
const FILTERS = ['All', 'Decks', 'Cards', 'Language', 'Deck scope', 'Visible'];

function Chips({ active }) {
  return (
    <div data-mx-node="search/filters" style={{ display: 'flex', gap: 'var(--memox-space-2)', overflowX: 'auto', paddingBottom: 'var(--memox-space-1)' }}>
      {FILTERS.map((f, i) => <MxChip key={f} label={f} selected={i === active} node={'search/filter-' + i} />)}
    </div>
  );
}

window.MemoXSearch = window.MemoXSearch || {};
window.MemoXSearch.Chips = Chips;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const Chips = (window.MemoXSearch || {}).Chips;
