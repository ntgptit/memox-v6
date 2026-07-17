import type { ReactNode } from 'react';

export interface ConfirmDialogProps {
  /** Scrim placement — `end` for a sheet, `center` for a dialog. @default 'center' */
  align?: 'center' | 'end';
  /** DOM node id for the scrim (export tooling only). */
  scrimNode?: string;
  /** Header icon (Material Symbols Rounded ligature name). */
  icon?: string;
  /** Header icon tint. `neutral` is the base; a destructive confirm uses `error`. */
  tone?: 'neutral' | 'warning' | 'error';
  /** Dialog title (caller-supplied from ARB). */
  title: ReactNode;
  /** Body text (caller-supplied from ARB). */
  text: ReactNode;
  /** DOM node id for the dialog (export tooling only). */
  dialogNode?: string;
  /** Full-width stacked action buttons — exactly one primary/confirm; cancel is `ghost`. */
  actions: ReactNode;
}

/**
 * Centered scrim + dialog confirm overlay (icon, title, text, actions). Carries
 * no copy of its own — every string, node id, and action is passed in by the
 * caller (l10n stays owned there). Used across study-session / deck-settings / languages.
 */
export function ConfirmDialog(props: ConfirmDialogProps): JSX.Element;
