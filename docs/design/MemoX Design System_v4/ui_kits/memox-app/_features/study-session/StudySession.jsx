/* MemoX — Study session (NewLearn 5 stages + DueReview).
   States: stage1-review · stage2-match · stage3-guess · stage4-recall · stage5-fill · relearn · due-review · exit · resume-error · answer-save-error
   Feature-local components: components/{PromptCard,StageReview,StageMatch,StageGuess,
   StageRecall,StageFill,ExitDialog,AnswerSaveErrorDialog,ResumeErrorState}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxCard, MxButton } = NS;

const META = {
  'stage1-review': { label: 'Stage 1 · Review', done: 4, total: 25 },
  'stage2-match': { label: 'Stage 2 · Match', done: 8, total: 25 },
  'stage3-guess': { label: 'Stage 3 · Guess', done: 12, total: 25 },
  'stage4-recall': { label: 'Stage 4 · Recall', done: 16, total: 25 },
  'stage5-fill': { label: 'Stage 5 · Fill', done: 21, total: 25 },
  'relearn': { label: 'Stage 3 · Guess', done: 12, total: 25 },
  'due-review': { label: 'Review · due cards', done: 10, total: 20 },
  'exit': { label: 'Stage 1 · Review', done: 4, total: 25 },
  'answer-save-error': { label: 'Stage 5 · Fill', done: 21, total: 25 },
};

const Note = window.Note;

// Route a state to its stage component; due-review stays inline (not a NewLearn stage).
function Body({ state }) {
  const SS = window.MemoXStudySession;
  if (state === 'stage1-review' || state === 'exit') return <SS.StageReview />;
  if (state === 'stage2-match') return <SS.StageMatch />;
  if (state === 'stage3-guess' || state === 'relearn') return <SS.StageGuess relearn={state === 'relearn'} />;
  if (state === 'stage4-recall') return <SS.StageRecall />;
  if (state === 'stage5-fill' || state === 'answer-save-error') return <SS.StageFill />;
  // due-review
  return (
    <React.Fragment>
      <Note icon="schedule" tone="warning" text="Reviewing due cards — results update the Leitner box." />
      <MxCard node="study-session/card" style={{ alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-3)', minHeight: 'var(--memox-size-3xl)', justifyContent: 'center' }}>
        <div style={{ fontSize: 'var(--memox-font-size-3xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>학교</div>
        <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>school</div>
      </MxCard>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
        <MxButton variant="ghost" icon="replay" block node="study-session/due-relearn">Relearn</MxButton>
        <MxButton variant="primary" icon="arrow_forward" block node="study-session/due-next">Next</MxButton>
      </div>
    </React.Fragment>
  );
}

function StudySession({ state = 'stage1-review' }) {
  const SS = window.MemoXStudySession;
  if (state === 'resume-error') return <SS.ResumeErrorState />;

  const m = META[state] || META['stage1-review'];
  const bar = (
    <MxContextualAppBar variant="nested" node="study-session/appbar"
      leading={<MxIconButton icon="close" node="study-session/close" />}
      title={<window.ProgressHeader done={m.done} total={m.total} node="study-session/progress" />}
      actions={<MxIconButton icon="more_vert" node="study-session/options" />} />
  );

  const scaffold = (
    <MxScaffold node="study-session/screen" appBar={bar}>
      <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-primary)' }}>{m.label}</div>
      <Body state={state} />
    </MxScaffold>
  );

  if (state === 'exit') {
    return (
      <React.Fragment>
        {scaffold}
        <SS.ExitDialog />
      </React.Fragment>
    );
  }

  if (state === 'answer-save-error') {
    return (
      <React.Fragment>
        {scaffold}
        <SS.AnswerSaveErrorDialog />
      </React.Fragment>
    );
  }

  return scaffold;
}

window.StudySession = StudySession;
})();
