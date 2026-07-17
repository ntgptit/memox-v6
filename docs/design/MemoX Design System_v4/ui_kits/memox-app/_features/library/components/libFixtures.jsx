/* Library fixtures + status helpers.
   ONE Deck model (domain: Library › Deck › Card). A deck's `parentId` is `null` at the root
   and its parent deck's `id` one level down (what the UI shows as a nested deck). There is NO
   separate "Subdeck" object — a "subdeck" is just a Deck with a non-null parentId. `children`
   is the count of child decks. id/parentId/children are not rendered (parity-neutral data). */
(function () {
const DECKS = [
  { id: 'd-topik1', parentId: null, icon: 'translate', tone: 'accent', name: 'Korean TOPIK I', cards: 486, due: 48, children: 5, progress: 64 },
  { id: 'd-grammar', parentId: null, icon: 'menu_book', tone: 'accent', name: 'Basic Grammar', cards: 180, new: 23, children: 0, progress: 40 },
  { id: 'd-conversation', parentId: null, icon: 'record_voice_over', tone: 'accent', name: 'Daily Conversation', cards: 150, upToDate: true, children: 3, progress: 100 },
  { id: 'd-hanja', parentId: null, icon: 'history_edu', tone: 'accent', name: 'Hanja Roots', cards: 320, due: 12, children: 0, progress: 72 },
  { id: 'd-travel', parentId: null, icon: 'travel_explore', tone: 'accent', name: 'Travel Phrases', cards: 96, new: 8, children: 2, progress: 30 },
  { id: 'd-business', parentId: null, icon: 'work', tone: 'accent', name: 'Business Korean', cards: 210, upToDate: true, children: 0, progress: 100 },
];
const DENSE = Array.from({ length: 22 }, (_, i) => {
  const b = DECKS[i % DECKS.length];
  return {
    ...b,
    name: i < 2 ? 'Advanced Idiomatic Expressions & Formal Register Workbook' : b.name + (i >= DECKS.length ? ' · set ' + (i - DECKS.length + 2) : ''),
    cards: i === 1 ? 1280 : b.cards, due: i === 0 ? 128 : b.due,
  };
});
// Child decks one level down — the SAME Deck shape, just parentId set to their parent deck.
// (The `SUBDECKS` export name is kept for the frozen subdeck-list feature wiring / node ids.)
const SUBDECKS = [
  { id: 'd-topik1-greetings', parentId: 'd-topik1', icon: 'waving_hand', tone: 'accent', name: 'Greetings & introductions', cards: 42, due: 8, children: 0, progress: 82 },
  { id: 'd-topik1-numbers', parentId: 'd-topik1', icon: 'numbers', tone: 'accent', name: 'Numbers & counting', cards: 55, upToDate: true, children: 0, progress: 100 },
  { id: 'd-topik1-family', parentId: 'd-topik1', icon: 'diversity_3', tone: 'accent', name: 'Family & relationships', cards: 38, new: 6, children: 0, progress: 24 },
  { id: 'd-topik1-food', parentId: 'd-topik1', icon: 'restaurant', tone: 'accent', name: 'Food & dining', cards: 47, due: 15, children: 0, progress: 51 },
  { id: 'd-topik1-directions', parentId: 'd-topik1', icon: 'directions', tone: 'accent', name: 'Directions & transport', cards: 35, upToDate: true, children: 0, progress: 100 },
];

// Post-create OUTCOME decks (§10). A just-created deck is ALWAYS empty — 0 cards, no due/new,
// no progress — and carries the name the user typed in the create flow. Rendered highlighted
// (shared DeckCard + `newBadge`) at the TOP of the list; never an existing populated deck.
// NEW_DECK = first-run success (the only deck); NEW_DECK_ROOT = a 2nd+ deck in the root Library;
// NEW_DECK_CHILD = a new child deck inside a parent (nested success).
const NEW_DECK = { id: 'd-new-first', parentId: null, icon: 'style', tone: 'accent', name: 'Korean TOPIK I', cards: 0, children: 0, progress: 0 };
const NEW_DECK_ROOT = { id: 'd-new-root', parentId: null, icon: 'style', tone: 'accent', name: 'Korean TOPIK II', cards: 0, children: 0, progress: 0 };
const NEW_DECK_CHILD = { id: 'd-new-child', parentId: 'd-topik1', icon: 'style', tone: 'accent', name: 'Grammar', cards: 0, children: 0, progress: 0 };

// Semantic status text: Due→warning, New→info(accent), Up-to-date→success.
function Status({ d }) {
  if (d.due > 0) return <span style={{ color: 'var(--memox-on-warning-soft)', fontWeight: 'var(--memox-font-weight-semibold)' }}>{d.due > 99 ? '99+' : d.due} due</span>;
  if (d.new > 0) return <span style={{ color: 'var(--memox-accent)', fontWeight: 'var(--memox-font-weight-semibold)' }}>{d.new} new</span>;
  return <span style={{ color: 'var(--memox-on-success-soft)', fontWeight: 'var(--memox-font-weight-semibold)' }}>Up to date</span>;
}
// Exactly TWO metadata groups (§7): card count · status. A brand-new EMPTY deck (0 cards) has
// no due/new/up-to-date status yet — show the count ALONE, never a misleading "Up to date".
function deckMeta(d) {
  if (d.cards === 0) return d.cards + ' cards';
  return <React.Fragment>{d.cards.toLocaleString()} cards · <Status d={d} /></React.Fragment>;
}

window.MemoXLibrary = Object.assign(window.MemoXLibrary || {}, { DECKS, DENSE, SUBDECKS, NEW_DECK, NEW_DECK_ROOT, NEW_DECK_CHILD, Status, deckMeta });
})();

export const libFixtures = window.MemoXLibrary;
