/* MemoX — Game: Recall. States: before-reveal · revealed · forgot · remembered · complete
   Feature-local components: components/{MeaningPanel}.jsx. Prompt card is shared StudyPromptCard. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton } = NS;
const { MeaningPanel } = window.MemoXRecallMode;

const Note = window.Note;

function RecallMode({ state = 'before-reveal' }) {
  const revealed = state === 'revealed' || state === 'forgot' || state === 'remembered';
  const bar = (
    <MxContextualAppBar variant="nested" node="recall-mode/appbar" title="Recall"
      leading={<MxIconButton icon="arrow_back" node="recall-mode/back" />}
      actions={<MxIconButton icon="more_vert" node="recall-mode/options" />} />
  );

  if (state === 'complete') {
    return (
      <MxScaffold node="recall-mode/screen" appBar={bar}>
        <window.ProgressHeader done={20} total={20} node="recall-mode/progress" />
        <window.EmptyState node="recall-mode/complete" icon="celebration" tone="success" title="Round complete!"
          text="You've reviewed the words in this round."
          action={<MxButton variant="primary" icon="arrow_forward" node="recall-mode/next">Next round</MxButton>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="recall-mode/screen" appBar={bar}>
      <window.ProgressHeader done={12} total={20} node="recall-mode/progress" />

      <window.StudyPromptCard term="친구" nodePrefix="recall-mode" fill />

      <MeaningPanel revealed={revealed} />

      {state === 'forgot' ? <Note icon="replay" tone="warning" text="You'll see this word again this round." /> : null}
      {state === 'remembered' ? <Note icon="check_circle" tone="success" text="Nice! Moving to the next card." /> : null}

      {/* action anchored at the bottom (thumb zone); reclaim the unused bottom-nav padding */}
      <div style={{ marginBottom: 'calc(-1 * var(--memox-bottom-nav-height))' }}>
        {state === 'before-reveal' ? (
          <MxButton variant="primary" icon="visibility" block size="lg" node="recall-mode/reveal">Show</MxButton>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
            <MxButton variant={state === 'forgot' ? 'primary' : 'ghost'} danger={state === 'forgot'} block node="recall-mode/forgot">Forgot</MxButton>
            <MxButton variant="primary" block node="recall-mode/remembered">Got it</MxButton>
          </div>
        )}
      </div>
    </MxScaffold>
  );
}

window.RecallMode = RecallMode;
})();
