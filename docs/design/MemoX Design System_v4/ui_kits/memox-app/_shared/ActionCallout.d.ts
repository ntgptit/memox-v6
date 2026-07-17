import type { ReactNode } from 'react';

export interface ActionCalloutProps {
  /** Soft-tint tone — picks the `*-soft` / `on-*-soft` token pair. `warning` is the base. @default 'warning' */
  tone?: 'primary' | 'accent' | 'info' | 'warning' | 'success' | 'error';
  /** Leading status icon (Material Symbols Rounded ligature name). */
  icon: string;
  /** Optional heading line above the message (bold). When set the banner uses the stacked layout. */
  title?: ReactNode;
  /** Inline message (supplied by the caller from ARB). */
  text: ReactNode;
  /** Optional trailing action, usually a small `MxButton`. In the titled layout it sits under the text. */
  action?: ReactNode;
  /** When set, renders a trailing dismiss (×) button (MxIconButton) carrying this `data-mx-node`. */
  dismissNode?: string;
  /** Handler run when the dismiss (×) is activated — e.g. hide the callout and restore the FAB.
   *  Wired to the dismiss MxIconButton's `onClick`; only meaningful alongside `dismissNode`. */
  onDismiss?: () => void;
  node?: string;
}

/**
 * Soft-tinted inline banner (icon + message) with an optional trailing action and, in the titled
 * layout, an optional dismiss (×). Shared by import dup-warning / mode-picker not-enough (no title)
 * and the create-deck success/resume callouts (title + dismiss). Tinted via the `*-soft` token pair.
 */
export function ActionCallout(props: ActionCalloutProps): JSX.Element;
