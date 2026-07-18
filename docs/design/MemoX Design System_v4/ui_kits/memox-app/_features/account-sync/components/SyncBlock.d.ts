export interface SyncBlockProps {
  /**
   * Sync status. Omit for the synced base (Synced + Sync now); `syncing` shows a
   * progress bar, `offline` a will-sync note, `conflict` an UNRESOLVED conflict that
   * pauses sync and routes to explicit Compare/decision — no last-write-wins / no default
   * cloud-wins (ADR-008 / resolve-sync-conflict.md).
   */
  state?: 'syncing' | 'offline' | 'conflict';
}

/**
 * Account-sync status card, varying by state. The account-sync screen is DEFERRED
 * (WBS S.22) — there is no Flutter counterpart yet, recorded as a `deferred-screen`
 * exception.
 */
export function SyncBlock(props: SyncBlockProps): JSX.Element;
