/* MemoX — Study-result local: FinalizingView (saving/committing the session to SRS).
   retry=true reframes it as a re-attempt after a finalize error. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxScaffold, MxCard } = NS;

function FinalizingView({ bar, retry }) {
  const { ResultHero } = window.MemoXStudyResult || {};
  const S = window.Skeleton;
  return (
    <MxScaffold node="study-result/screen" appBar={bar}>
      {/* KIT-42-04: saving/finalizing progress is a polite live region (aria-busy while
          committing) so the reader hears the saving state and its later resolution. The
          announce wrapper holds only the hero text, so scaffold gaps stay unchanged. */}
      <div role="status" aria-live="polite" aria-busy="true">
        <ResultHero icon={retry ? 'refresh' : 'cloud_sync'} tone="accent"
          title={retry ? 'Retrying…' : 'Saving your results…'}
          text={retry ? 'Trying again to update your review schedule and streak.' : 'Updating your review schedule and streak.'} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--memox-space-3)' }}>
        {[0, 1, 2].map((i) => (
          <MxCard key={i} variant="muted" padding="sm" node={'study-result/finalizing-stat-' + i} style={{ alignItems: 'center' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 'var(--memox-space-2)', width: '100%' }}>
              <S w={44} h={22} /><S w="64%" h={10} />
            </div>
          </MxCard>
        ))}
      </div>
      <S h={120} r={20} />
    </MxScaffold>
  );
}

window.MemoXStudyResult = window.MemoXStudyResult || {};
window.MemoXStudyResult.FinalizingView = FinalizingView;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const FinalizingView = (window.MemoXStudyResult || {}).FinalizingView;
