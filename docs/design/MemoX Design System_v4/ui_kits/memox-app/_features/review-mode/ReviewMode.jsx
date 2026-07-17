/* MemoX — Review. States: browsing · editing · audio · end
   Feature-local components: components/{MeaningCard}.jsx. Term card is shared StudyPromptCard. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton } = NS;
const { MeaningCard } = window.MemoXReviewMode;

function ReviewMode({ state = 'browsing' }) {
  const editing = state === 'editing';
  const bar = (
    <MxContextualAppBar variant="nested" node="review-mode/appbar" title="Review"
      leading={<MxIconButton icon="arrow_back" node="review-mode/back" />}
      actions={<React.Fragment>
        <MxIconButton icon="format_size" node="review-mode/text-size" />
        <MxIconButton icon="more_vert" node="review-mode/options" />
      </React.Fragment>} />
  );

  if (state === 'loading') {
    const S = window.Skeleton;
    return (
      <MxScaffold node="review-mode/screen" appBar={bar}>
        <S h={12} r={999} />
        <S h={220} r={20} style={{ marginTop: 'var(--memox-space-4)' }} />
        <S h={260} r={20} style={{ marginTop: 'var(--memox-space-4)' }} />
      </MxScaffold>
    );
  }

  if (state === 'error') {
    return (
      <MxScaffold node="review-mode/screen" appBar={bar}>
        <window.EmptyState node="review-mode/error" icon="cloud_off" tone="error" title="Couldn't load review"
          text="Something went wrong loading your cards. Check your connection and try again."
          action={<MxButton variant="primary" icon="refresh" node="review-mode/retry">Try again</MxButton>} />
      </MxScaffold>
    );
  }

  if (state === 'end') {
    return (
      <MxScaffold node="review-mode/screen" appBar={bar}>
        <window.EmptyState node="review-mode/end" icon="done_all" tone="success" title="All reviewed"
          text="You've gone through every card in this deck."
          action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
            <MxButton variant="primary" icon="school" block node="review-mode/study-now">Study now</MxButton>
            <MxButton variant="ghost" icon="arrow_back" block node="review-mode/back-deck">Back to deck</MxButton>
          </div>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="review-mode/screen" appBar={bar}>
      <window.ProgressHeader done={7} total={20} node="review-mode/progress" />

      <MeaningCard editing={editing} />

      <window.StudyPromptCard term="학교" nodePrefix="review-mode" fill editable={false} playing={state === 'audio'} />

      <div style={{ marginBottom: 'calc(-1 * var(--memox-bottom-nav-height))', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 'var(--memox-space-4)', color: 'var(--memox-text-tertiary)' }}>
        <MxIconButton icon="chevron_left" node="review-mode/prev" />
        <span style={{ fontSize: 'var(--memox-font-size-sm)' }}>Swipe to continue</span>
        <MxIconButton icon="chevron_right" node="review-mode/next" />
      </div>
    </MxScaffold>
  );
}

window.ReviewMode = ReviewMode;
})();
