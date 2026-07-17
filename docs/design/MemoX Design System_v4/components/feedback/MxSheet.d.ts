import type { ReactNode } from 'react';

/**
 * The one bottom sheet — a surface that rises from the bottom edge with a drag
 * handle, optional title, and a height-capped scrollable body that honours the
 * bottom safe-area. Base class `sheet`.
 * @startingPoint section="Feedback" subtitle="Sheet — bottom sheet with handle + scroll" viewport="390x420"
 *
 * Accessibility / dismissal contract:
 * - role="dialog" + aria-modal="true"; `title` is exposed via aria-labelledby
 *   (falls back to `ariaLabel` when there is no visible title).
 * - Focus moves into the sheet on open and returns to the opener on close.
 * - Escape and scrim tap invoke `onDismiss` only when `dismissible`.
 * - The drag handle is decorative (aria-hidden); dismissal is via scrim/Escape/action.
 * - The body scrolls internally; `padding-bottom` reserves `--memox-safe-area-bottom`.
 */
export interface MxSheetProps {
  /** Mounts the sheet. `false` renders nothing. @default true */
  open?: boolean;
  /** Optional title above the body. */
  title?: string;
  /** Sheet content — the scrollable region. */
  children?: ReactNode;
  /** Height cap override (a token or ratio/length). Defaults to the base-class cap. */
  maxHeight?: string;
  /** Allow Escape / scrim-tap dismissal. @default true */
  dismissible?: boolean;
  /** Called on Escape or scrim tap when `dismissible`. */
  onDismiss?: () => void;
  /** Accessible name when there is no visible `title`. */
  ariaLabel?: string;
  node?: string;
  className?: string;
}

export function MxSheet(props: MxSheetProps): JSX.Element | null;
