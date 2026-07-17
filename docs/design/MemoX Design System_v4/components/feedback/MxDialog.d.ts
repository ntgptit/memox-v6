import type { ReactNode } from 'react';

/**
 * The one centered modal decision surface — scrim + raised panel holding a
 * title, body, and trailing actions. Blocking and focus-trapped. Base class `dialog`.
 * @startingPoint section="Feedback" subtitle="Dialog — centered modal decision surface" viewport="360x260"
 *
 * Accessibility / focus-trap contract:
 * - role="dialog" + aria-modal="true"; `title` is exposed via aria-labelledby
 *   (falls back to `ariaLabel` when there is no visible title).
 * - On open, focus moves to the panel (tabIndex=-1) and Tab is confined to it;
 *   on close, focus returns to the opener. The host app / RN `Modal` enforces the trap.
 * - Escape and scrim tap invoke `onDismiss` only when `dismissible`.
 * - Reduced motion: the enter/exit fade honours prefers-reduced-motion.
 */
export interface MxDialogProps {
  /** Mounts the dialog. `false` renders nothing. @default true */
  open?: boolean;
  /** Title — the dialog's accessible name and top-level label. */
  title?: string;
  /** Body content (message, form, list). */
  children?: ReactNode;
  /** Action row (MxButton(s)) — right-aligned, at most one primary. */
  actions?: ReactNode;
  /** Allow Escape / scrim-tap dismissal. Set false for a required decision. @default true */
  dismissible?: boolean;
  /** Called on Escape or scrim tap when `dismissible`. */
  onDismiss?: () => void;
  /** Accessible name when there is no visible `title`. */
  ariaLabel?: string;
  node?: string;
  className?: string;
}

export function MxDialog(props: MxDialogProps): JSX.Element | null;
