import type { ReactNode } from 'react';

export type MxContextualAppBarVariant =
  | 'root'        // tab destination: left title + actions/notification/avatar (flat, no scroll change)
  | 'nested'      // detail screen: back + title + actions (flat, no scroll change)
  | 'search'      // search mode: back + filled search field + clear (flat, no scroll change)
  | 'selection'   // selection MODE bar: close + "N selected" + selection actions (surface + hairline)
  | 'modal';      // full-screen form/task MODE bar: close + centered title + primary action (surface + hairline)

export interface MxContextualAppBarProps {
  variant?: MxContextualAppBarVariant;
  /** root/nested/search only. Retained to pin gallery states; it NO LONGER changes the bar visually
   *  (top == scrolled — the bar is flat at every scroll position). */
  collapsed?: boolean;
  /** Destination / nested title (single line, truncates). Centered in the `modal` variant. */
  title?: string;
  /** selection variant — number of selected items. */
  count?: number;
  /** search variant — { value, placeholder }. */
  search?: { value?: string; placeholder?: string };
  /** Leading slot override; auto-provided (back for nested/search, close for modal/selection). */
  leading?: ReactNode;
  /** Right-side actions (icon buttons). MAX 2 directly visible; a 3rd+ goes to overflow. */
  actions?: ReactNode;
  /** Notification action with badge — { count } (numeric, 99+ cap) or { dot }. Omit when count is 0. */
  notification?: { count?: number; dot?: boolean };
  /** Avatar action (MxAvatar). Counts as one of the two allowed actions. Root variant only. */
  avatar?: ReactNode;
  node?: string;
  className?: string;
}

/**
 * The one app bar — a minimal top bar at a single 56px height. Base class `cappbar`.
 * Variants root/nested/search are FLAT: one background = the screen colour, no surface/divider/shadow
 * on scroll (top == scrolled). selection/modal are mode bars carrying a surface + hairline.
 *
 * Accessibility contract:
 * - Reading / focus order: leading nav → title → actions → notification → avatar.
 * - Title is not focusable (not interactive); it carries no role beyond text.
 * - Every icon-only action has an aria-label; the notification label announces unread count
 *   ("Notifications, 3 unread"); the selection count uses role="status".
 * - Foreground/divider/badge use theme tokens meeting >=4.5:1 for text.
 * - The bar background does not animate on scroll (root/nested/search are flat); only the title
 *   fade-in honours prefers-reduced-motion.
 */
export function MxContextualAppBar(props: MxContextualAppBarProps): JSX.Element;
