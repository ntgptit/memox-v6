/* MemoX — Mode picker ("Single mode"). States: default · scope-dropdown · not-enough
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
  const bar = <MxContextualAppBar variant="nested" title="Single mode" node="mode-picker/appbar" leading={<MxIconButton icon="arrow_back" node="mode-picker/back" />} />;

  const base = (
    <MxScaffold node="mode-picker/screen" appBar={bar}>
      {notEnough ? (
        <window.ActionCallout node="mode-picker/not-enough" icon="info" text="This deck needs at least 4 words to play."
          action={<MxButton variant="primary" size="sm" node="mode-picker/add-cards">Add words</MxButton>} />
      ) : null}

      <ScopeCard />

      <MxList node="mode-picker/modes">{MODES.map((g) => <ModeOption key={g.id} g={g} disabled={notEnough} />)}</MxList>

      <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)', padding: 'var(--memox-space-1) 0' }}>5 words per round · change in Settings</div>
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
