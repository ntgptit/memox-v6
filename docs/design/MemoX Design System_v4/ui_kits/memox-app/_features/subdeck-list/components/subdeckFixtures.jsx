/* Fixtures for the child-deck list screen (NO cards on this screen).
   ONE Deck model: these are child decks (parentId = their parent deck's id) — the SAME Deck
   shape as a root deck, so the shared DeckCard renders them identically:
   { id, parentId, name, cards, due|new|upToDate, children, progress }. */
(function () {
// Child decks one level down — same Deck shape as a root deck, with parentId set.
const SUBDECKS = [
  { id: 'd-topik1-greetings', parentId: 'd-topik1', icon: 'waving_hand', tone: 'accent', name: 'Greetings & introductions', cards: 42, due: 8, children: 0, progress: 82 },
  { id: 'd-topik1-numbers', parentId: 'd-topik1', icon: 'numbers', tone: 'accent', name: 'Numbers & counting', cards: 55, upToDate: true, children: 0, progress: 100 },
  { id: 'd-topik1-family', parentId: 'd-topik1', icon: 'diversity_3', tone: 'accent', name: 'Family & relationships', cards: 38, new: 6, children: 0, progress: 24 },
  { id: 'd-topik1-food', parentId: 'd-topik1', icon: 'restaurant', tone: 'accent', name: 'Food & dining', cards: 47, due: 15, children: 0, progress: 51 },
  { id: 'd-topik1-directions', parentId: 'd-topik1', icon: 'directions', tone: 'accent', name: 'Directions & transport', cards: 35, upToDate: true, children: 0, progress: 100 },
];
const DENSE = Array.from({ length: 20 }, (_, i) => {
  const b = SUBDECKS[i % SUBDECKS.length];
  return {
    ...b,
    name: i < 2 ? 'Formal & Honorific Speech Registers — Advanced Workbook' : b.name + (i >= SUBDECKS.length ? ' · set ' + (i - SUBDECKS.length + 2) : ''),
    cards: i === 1 ? 1280 : b.cards, due: i === 0 ? 128 : b.due,
  };
});
// Breadcrumb trails (root → current). The last crumb is the current level (bold, non-link);
// ancestors are tappable. TRAIL_DEEP exercises the collapse-the-middle behaviour.
const TRAIL = [
  { label: 'Library', node: 'subdeck-list/crumb-library' },
  { label: 'Korean TOPIK I', current: true },
];
const TRAIL_DEEP = [
  { label: 'Library', node: 'subdeck-list/crumb-library' },
  { label: 'Korean TOPIK I', node: 'subdeck-list/crumb-deck' },
  { label: 'Grammar', node: 'subdeck-list/crumb-grammar' },
  { label: 'Verbs', node: 'subdeck-list/crumb-verbs' },
  { label: 'Irregular verbs', current: true },
];

// Compact deck aggregate shown as a muted annotation on the SUBDECKS section label
// (the subdeck count is omitted — it is obvious from the list itself).
function summary(list) {
  const cards = list.reduce((n, s) => n + s.cards, 0);
  const due = list.reduce((n, s) => n + (s.due || 0), 0);
  return cards.toLocaleString() + ' cards · ' + due + ' due';
}
window.MemoXSubdeckList = Object.assign(window.MemoXSubdeckList || {}, { SUBDECKS, DENSE, summary, TRAIL, TRAIL_DEEP });
})();

export const subdeckFixtures = window.MemoXSubdeckList;
