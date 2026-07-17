/* MemoX — Game: Fill. States: waiting · typing · hint · correct · wrong · complete
   Feature-local components: components/{CharCompare,InputBox}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxCard, MxIconButton, MxButton } = NS;
const { CharCompare, InputBox } = window.MemoXFillMode;

const Note = window.Note;

const INPUT = {
  waiting: { content: null, placeholder: 'Type the Korean word…' },
  typing: { content: '친' },
  hint: { content: '친 _' },
  correct: { content: '친구', tone: 'correct' },
  wrong: { content: <CharCompare />, tone: 'wrong' },
};

function FillMode({ state = 'waiting' }) {
  const bar = (
    <MxContextualAppBar variant="nested" node="fill-mode/appbar" title="Fill"
      leading={<MxIconButton icon="arrow_back" node="fill-mode/back" />}
      actions={<MxIconButton icon="more_vert" node="fill-mode/options" />} />
  );

  if (state === 'complete') {
    return (
      <MxScaffold node="fill-mode/screen" appBar={bar}>
        <window.ProgressHeader done={20} total={20} node="fill-mode/progress" />
        <window.EmptyState node="fill-mode/complete" icon="celebration" tone="success" title="Round complete!"
          text="You typed the words correctly."
          action={<MxButton variant="primary" icon="arrow_forward" node="fill-mode/next">Next round</MxButton>} />
      </MxScaffold>
    );
  }

  const inp = INPUT[state] || INPUT.waiting;
  let controls;
  if (state === 'correct') {
    controls = <MxButton variant="primary" icon="arrow_forward" block node="fill-mode/next">Next</MxButton>;
  } else if (state === 'wrong') {
    controls = (
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
        <MxButton variant="outline" block node="fill-mode/accept">Correct</MxButton>
        <MxButton variant="primary" block node="fill-mode/retry">Retry</MxButton>
      </div>
    );
  } else {
    controls = (
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
        <MxButton variant="ghost" icon="lightbulb" block node="fill-mode/hint">Help</MxButton>
        <MxButton variant="primary" block disabled={state === 'waiting'} node="fill-mode/check">Check</MxButton>
      </div>
    );
  }

  return (
    <MxScaffold node="fill-mode/screen" appBar={bar}>
      <window.ProgressHeader done={16} total={20} node="fill-mode/progress" />

      <MxCard node="fill-mode/meaning" style={{ flex: 1, justifyContent: 'center', alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-2)', padding: 'var(--memox-space-6)' }}>
        <window.SectionLabel style={{ margin: 0 }}>MEANING</window.SectionLabel>
        <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>friend</div>
      </MxCard>

      <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>Type the term (Korean)</div>
      <InputBox {...inp} />

      {state === 'hint' ? <Note icon="lightbulb" tone="warning" text="Hint: 2 characters, starts with 친" /> : null}
      {state === 'wrong' ? (
        <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)' }}>
          Answer: <b style={{ color: 'var(--memox-success)' }}>친구</b>
        </div>
      ) : null}

      <div style={{ marginBottom: 'calc(-1 * var(--memox-bottom-nav-height))' }}>{controls}</div>
    </MxScaffold>
  );
}

window.FillMode = FillMode;
})();
