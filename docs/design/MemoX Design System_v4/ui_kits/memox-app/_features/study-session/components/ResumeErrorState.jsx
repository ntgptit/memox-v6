/* MemoX — Study-session local: ResumeErrorState (full screen for resume-error).
   Owns its own app bar since this state has no progress bar. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton } = NS;

function ResumeErrorState() {
  const errBar = (
    <MxContextualAppBar variant="nested" node="study-session/appbar"
      leading={<MxIconButton icon="close" node="study-session/close" />}
      title={<span style={{ fontSize: 'var(--memox-font-size-base)', fontWeight: 'var(--memox-font-weight-bold)' }}>Resume session</span>} />
  );
  return (
    <MxScaffold node="study-session/screen" appBar={errBar}>
      <window.EmptyState node="study-session/resume-error" icon="play_disabled" tone="error" title="Couldn't resume your session"
        text="We couldn't restore where you left off. Restart this session or go back to the deck."
        action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
          <MxButton variant="primary" icon="refresh" block node="study-session/resume-retry">Restart session</MxButton>
          <MxButton variant="ghost" block node="study-session/resume-back">Back to deck</MxButton>
        </div>} />
    </MxScaffold>
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.ResumeErrorState = ResumeErrorState;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ResumeErrorState = (window.MemoXStudySession || {}).ResumeErrorState;
