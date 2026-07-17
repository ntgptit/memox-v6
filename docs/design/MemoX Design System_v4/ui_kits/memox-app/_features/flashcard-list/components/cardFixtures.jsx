/* Flashcard List fixtures. Domain: Deck › Card (this is the deepest, final deck — NO
   subdecks here). Card shape: { term, meaning, status: new|due|mastered, hidden? }.
   Meanings are intentionally a MIX of short (one line) and long (multi-line) definitions so
   the loaded state exercises both cases: short cards reserve the (invisible) toggle row and
   long cards clamp to one line + a real "Show more" — every card the same height. */
(function () {
const CARDS = [
  { term: '안녕하세요', meaning: 'Hello (formal). A polite everyday greeting used with strangers, elders, or in professional settings — literally “are you at peace?”', status: 'due' },
  { term: '감사합니다', meaning: 'Thank you (formal).', status: 'mastered' },
  { term: '사랑', meaning: 'love; affection — a deep feeling of care, attachment, or romantic devotion toward a person, place, or thing.', status: 'new' },
  { term: '공부하다', meaning: 'to study; to learn.', status: 'due' },
  { term: '맛있다', meaning: 'to be delicious; tasty (of food or drink).', status: 'mastered' },
  { term: '어렵다', meaning: 'to be difficult or hard — not easy to do, understand, or endure.', status: 'new', hidden: true },
];
const MIN = [CARDS[1]]; // a single short-meaning card (minimum data)
const DENSE = Array.from({ length: 16 }, (_, i) => CARDS[i % CARDS.length]);
const LONG = [
  { term: '전화번호부에 등록되지 않은 사람', meaning: 'a person who is not registered in the phone directory; someone whose contact details are unavailable — used when explaining why a call could not be completed', status: 'due' },
  ...CARDS.slice(1),
];
const FILTERS = ['All', 'New', 'Due', 'Mastered'];
// Breadcrumb trail: this final deck is a subdeck of Korean TOPIK I.
const TRAIL = [
  { label: 'Library', node: 'flashcard-list/crumb-library' },
  { label: 'Korean TOPIK I', node: 'flashcard-list/crumb-deck' },
  { label: 'Numbers & counting', current: true },
];
// Compact study aggregate shown as a muted annotation on the CARDS section label
// (the total is obvious from the single card list, so it is omitted).
function summary(list) {
  const due = list.filter((c) => c.status === 'due').length;
  const mastered = list.filter((c) => c.status === 'mastered').length;
  return due + ' due · ' + mastered + ' mastered';
}
window.MemoXFlashcardList = Object.assign(window.MemoXFlashcardList || {}, { CARDS, MIN, DENSE, LONG, FILTERS, TRAIL, summary });
})();

export const cardFixtures = window.MemoXFlashcardList;
