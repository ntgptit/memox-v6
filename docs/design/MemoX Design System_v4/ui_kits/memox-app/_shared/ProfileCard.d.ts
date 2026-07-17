import type { ReactNode } from 'react';

export interface ProfileCardProps {
  /** `data-mx-node` id for the card (per-caller: settings/profile · account/profile). */
  node?: string;
  /** Optional trailing badge — account-sync passes its ALPHA tag; settings omits it. */
  badge?: ReactNode;
}

/**
 * Avatar + name + email identity card. Owns the row shared by settings
 * (settings/profile) and account-sync (account/profile). The name/email are a
 * static scaffold fixture; `node` + optional `badge` are the only per-caller inputs.
 *
 * Flutter parity note: the v1 Flutter card (`MxProfileCard`) shows the app's
 * **local** identity (wordmark + on-device subtitle, D-027 — no account/sync in v1),
 * not a signed-in name/email. `badge` is account-sync only (deferred, WBS S.22).
 */
export function ProfileCard(props: ProfileCardProps): JSX.Element;
