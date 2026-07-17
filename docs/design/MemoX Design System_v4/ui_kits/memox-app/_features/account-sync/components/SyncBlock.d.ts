export interface SyncBlockProps {
  /**
   * Sync status. Omit for the synced base (Synced + Sync now); `syncing` shows a
   * progress bar, `offline` a will-sync note, `conflict` a merged/last-write-wins
   * banner.
   */
  state?: 'syncing' | 'offline' | 'conflict';
}

/**
 * Account-sync status card, varying by state. The account-sync screen is DEFERRED
 * (WBS S.22) — there is no Flutter counterpart yet, recorded as a `deferred-screen`
 * exception.
 */
export function SyncBlock(props: SyncBlockProps): JSX.Element;
