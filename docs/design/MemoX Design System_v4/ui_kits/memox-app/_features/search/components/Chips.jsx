/* MemoX — Search local: Chips (status filter chip row). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxChip } = NS;

const FILTERS = ['All', 'New', 'Due', 'Mastered'];

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
