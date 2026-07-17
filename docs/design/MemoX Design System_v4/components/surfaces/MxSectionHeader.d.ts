import type { ReactNode } from 'react';

export interface MxSectionHeaderProps {
  title?: ReactNode;
  /** Optional sub-label under the title. */
  caption?: ReactNode;
  /** Trailing action label (e.g. "See all"). Fires on click AND Enter/Space. */
  action?: ReactNode;
  onAction?: () => void;
  /** Accessible name for the action when its content is non-text (e.g. an icon). */
  actionLabel?: string;
  node?: string;
}

/** Section / list header with title, optional caption, and a trailing text action. Base class `section-head`. */
export function MxSectionHeader(props: MxSectionHeaderProps): JSX.Element;
