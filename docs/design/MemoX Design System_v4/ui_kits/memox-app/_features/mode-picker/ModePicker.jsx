/* MemoX — Practice mode picker. Selection never starts implicitly; the explicit Start session
   CTA creates a Practice Session. States: default · scope-dropdown · not-enough
   Feature-local components: components/{ModeOption,ScopeCard,ScopeSheet}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxButton, MxIconButton, MxList } = NS;
const { ModeOption, ScopeCard, ScopeSheet } = window.MemoXModePicker;

const MODES = [
  { icon: 'style', name: 'Review', desc: 'Browse and flip cards', id: 'review' },
  { icon: 'join_inner', name: 'Match', desc: 'Match terms to meanings', id: 'match' },
  { icon: 'quiz', name: 'Guess', desc: 'Pick the right meaning', id: 'guess' },
  { icon: 'psychology', name: 'Recall', desc: 'Recall, then self-grade', id: 'recall' },
  { icon: 'keyboard', name: 'Fill', desc: 'Type the term from its meaning', id: 'fill' },
];

function ModePicker({ state = 'default' }) {
  const notEnough = state === 'not-enough';
  const [selectedMode, setSelectedMode] = React.useState('review');
  const bar = <MxContextualAppBar variant="nested" title="Practice mode" node="mode-picker/appbar" leading={<MxIconButton icon="arrow_back" node="mode-picker/back" />} />;

  const base = (
    <MxScaffold node="mode-picker/screen" appBar={bar}>
      {notEnough ? (
        <window.ActionCallout node="mode-picker/not-enough" icon="info" text="Guess practice needs at least 5 cards with distinct meanings."
          action={<MxButton variant="primary" size="sm" node="mode-picker/add-cards">Add cards</MxButton>} />
      ) : null}

      <ScopeCard />

      <MxList node="mode-picker/modes">{MODES.map((g) => (
        <ModeOption key={g.id} g={g} disabled={notEnough} selected={selectedMode === g.id}
          onSelect={() => setSelectedMode(g.id)} />
      ))}</MxList>

      <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)', padding: 'var(--memox-space-1) 0' }}>Practice does not activate new cards or schedule SRS.</div>
      <MxButton variant="primary" block size="lg" disabled={notEnough} node="mode-picker/start">Start session</MxButton>
    </MxScaffold>
  );

  if (state === 'scope-dropdown') {
    return (
      <React.Fragment>
        {base}
        <ScopeSheet />
      </React.Fragment>
    );
  }

  return base;
}

window.ModePicker = ModePicker;
})();
