/* MemoX — Game: Guess. States: waiting · correct · wrong · complete
   Feature-local component: components/PromptCard.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton } = NS;

const CHOICES = ['school', 'hospital', 'park', 'restaurant', 'library'];
// long-text fixture — proves the answer options wrap multi-line meanings and the rows grow.
const LONG_CHOICES = [
  'a place where students go to study and learn from teachers',
  'a building where sick or injured people are cared for by doctors',
  'a public area with grass and trees, used for rest and recreation',
  'a business that cooks and serves food and drinks to customers',
  'a place where books are kept for reading, study, or borrowing',
];

const Choice = window.ChoiceOption;

function toneFor(state, i) {
  if (state === 'correct') return i === 0 ? 'correct' : undefined;
  if (state === 'wrong') return i === 0 ? 'correct' : (i === 2 ? 'wrong' : undefined);
  return undefined;
}

function GuessMode({ state = 'waiting' }) {
  const bar = (
    <MxContextualAppBar variant="nested" node="guess-mode/appbar" title="Guess"
      leading={<MxIconButton icon="arrow_back" node="guess-mode/back" />}
      actions={<MxIconButton icon="more_vert" node="guess-mode/options" />} />
  );

  if (state === 'complete') {
    return (
      <MxScaffold node="guess-mode/screen" appBar={bar}>
        <window.ProgressHeader done={20} total={20} node="guess-mode/progress" />
        <window.EmptyState node="guess-mode/complete" icon="celebration" tone="success" title="Round complete!"
          text="You answered 5/5 correctly."
          action={<MxButton variant="primary" icon="arrow_forward" node="guess-mode/next">Next round</MxButton>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="guess-mode/screen" appBar={bar}>
      <window.ProgressHeader done={8} total={20} node="guess-mode/progress" />
      <window.StudyPromptCard term="학교" nodePrefix="guess-mode" />
      {/* 5 answer options fill the remaining body height as equal rows — taller, chunkier tap
          targets and no dead space below. minmax(min-content,1fr): short options fill to 1fr,
          long (multi-line) meanings GROW instead of clipping. Reclaims the (unused) bottom-nav
          padding so they fit. */}
      <div style={{ flex: '1 1 0', minHeight: 0, marginBottom: 'calc(-1 * var(--memox-bottom-nav-height))', display: 'grid', gridTemplateRows: 'repeat(5, minmax(min-content, 1fr))', gap: 'var(--memox-space-3)' }}>
        {(state === 'long-text' ? LONG_CHOICES : CHOICES).map((c, i) => <Choice key={i} text={c} tone={toneFor(state, i)} node={'guess-mode/choice-' + i} />)}
      </div>
    </MxScaffold>
  );
}

window.GuessMode = GuessMode;
})();
