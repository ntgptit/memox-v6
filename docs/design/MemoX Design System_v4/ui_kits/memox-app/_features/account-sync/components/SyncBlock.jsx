/* MemoX — Account-sync local: SyncBlock (sync status card, varies by state).
   Status callouts use the shared window.Note (K.4b banner tier 1). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard, MxButton } = NS;

function SyncBlock({ state }) {
  if (state === 'syncing') {
    return (
      <MxCard node="account/sync">
        <window.ListRow icon="sync" tone="accent" title="Syncing…" sub="Uploading changes" last node="account/sync-status" />
        {/* Standalone progress surface announced to AT (KIT-21-03): polite live region
            + aria-busy while the sync runs. Attribute-only — no pixel change. */}
        <div role="status" aria-live="polite" aria-busy="true" style={{ marginTop: 'var(--memox-space-3)' }}><window.ProgressBar value={60} height={8} node="account/sync-bar" /></div>
      </MxCard>
    );
  }
  if (state === 'offline') {
    return (
      <MxCard node="account/sync">
        <window.ListRow icon="cloud_off" tone="warning" title="Offline" sub="Will sync when you're back online" last node="account/sync-status" />
      </MxCard>
    );
  }
  if (state === 'conflict') {
    return (
      <MxCard node="account/sync" style={{ gap: 'var(--memox-space-3)' }}>
        <window.ListRow icon="merge_type" tone="success" title="Merged" sub="Kept the latest (last-write-wins)" last node="account/sync-status" />
        <window.Note icon="check_circle" tone="success" text="Your devices' data was merged safely." />
      </MxCard>
    );
  }
  return (
    <MxCard node="account/sync">
      <window.ListRow icon="cloud_done" tone="success" title="Synced" sub="Last: 14:02 today" last node="account/sync-status"
        trailing={<MxButton variant="outline" size="sm" node="account/sync-now">Sync now</MxButton>} />
    </MxCard>
  );
}

window.MemoXAccountSync = window.MemoXAccountSync || {};
window.MemoXAccountSync.SyncBlock = SyncBlock;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const SyncBlock = (window.MemoXAccountSync || {}).SyncBlock;
