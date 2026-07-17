/* MemoX — Study result. States: standard · goal-met · goal-missed · many-wrong · finalizing · retry-finalize · finalize-error
   Feature-local components: components/{ResultHero,StreakGoalCard,Cta,FinalizingView}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxCard, MxButton, MxLink } = NS;
const { ResultHero, StreakGoalCard, Cta, FinalizingView } = window.MemoXStudyResult;

const HEAD = {
  standard: { icon: 'task_alt', tone: 'accent', title: 'Session complete', text: 'You reviewed 24 cards this session.' },
  'goal-met': { icon: 'celebration', tone: 'success', title: 'Daily goal reached!', text: 'Streak +1 → 13 days in a row.' },
  'goal-missed': { icon: 'trending_up', tone: 'warning', title: 'Almost there!', text: '6 more minutes to hit today’s goal.' },
  'many-wrong': { icon: 'refresh', tone: 'error', title: 'A few shaky words', text: 'You missed 8 cards — review now to remember them longer.' },
};

function StudyResult({ state = 'standard' }) {
  const h = HEAD[state] || HEAD.standard;
  const met = state === 'goal-met';
  // Terminal summary page: exit only via the explicit bottom actions (no top-bar close).
  const bar = <MxContextualAppBar variant="root" node="study-result/appbar" title="Results" />;
  const showMistakes = state !== 'many-wrong'; // many-wrong already has a dedicated review CTA

  if (state === 'finalizing' || state === 'retry-finalize') {
    return <FinalizingView bar={bar} retry={state === 'retry-finalize'} />;
  }

  if (state === 'finalize-error') {
    return (
      <MxScaffold node="study-result/screen" appBar={bar}>
        <window.EmptyState announce="alert" node="study-result/finalize-error" icon="cloud_off" tone="error" title="Couldn't save your results"
          text="Your session finished, but we couldn't update your schedule. Retry so this session counts."
          action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
            <MxButton variant="primary" icon="refresh" block node="study-result/finalize-retry">Retry</MxButton>
            <MxButton variant="ghost" block node="study-result/finalize-later">Not now</MxButton>
          </div>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="study-result/screen" appBar={bar}>
      {/* KIT-42-04: the finished-session summary is a polite live region so the reader
          announces the result when this replaces the study session. Attribute-only. */}
      <div role="status" aria-live="polite" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-4)' }}>
        <ResultHero icon={h.icon} tone={h.tone} title={h.title} text={h.text} />

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--memox-space-3)' }}>
          {[['24', 'cards'], ['88%', 'correct'], ['6:30', 'min']].map(([n, l], i) => (
            <MxCard key={i} variant="muted" padding="sm" node={'study-result/stat-' + i} style={{ alignItems: 'center' }}>
              <window.Stat n={n} l={l} />
            </MxCard>
          ))}
        </div>

        {showMistakes ? (
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 'calc(-1 * var(--memox-space-2))' }}>
            <MxLink icon="replay" trailingIcon={null} size="sm" node="study-result/review-mistakes">Review mistakes</MxLink>
          </div>
        ) : null}

        <StreakGoalCard met={met} />

        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
          <Cta state={state} />
        </div>
      </div>
    </MxScaffold>
  );
}

window.StudyResult = StudyResult;
})();
