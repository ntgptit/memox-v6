import type { ReactNode } from 'react';

export interface MxMenuItem {
  /** Stable id passed to `onSelect`. */
  id: string;
  /** Visible label (single line, truncates). */
  label: ReactNode;
  /** Optional leading icon (Material Symbols name). A selected item with no icon shows `check`. */
  icon?: string;
  /** Marks the current choice — tinted row + `aria-current`. */
  selected?: boolean;
  /** Destructive action — recolors to error and tints on hover. */
  destructive?: boolean;
  /** Non-interactive: dimmed, unfocusable, blocks `onSelect`. */
  disabled?: boolean;
}

/**
 * The one action menu — a vertical list of labelled actions with optional icons and
 * selected / destructive / disabled item states; overflow scrolls inside the menu.
 * Frozen replacement for the ad-hoc MenuItem (incl. the disabled state). Base class `menu`.
 * @startingPoint section="Feedback" subtitle="Menu — action list with item states" viewport="260x300"
 *
 * Accessibility:
 * - role="menu"; each item is role="menuitem". Disabled items set `disabled` + `aria-disabled`.
 * - The selected item carries `aria-current`; icons are decorative (aria-hidden).
 * - Keyboard: items are natively focusable buttons; each gets a `:focus-visible` ring.
 */
export interface MxMenuProps {
  /** The actions, in order. */
  items: MxMenuItem[];
  /** Called with an item's `id` on activation (never fired for disabled items). */
  onSelect?: (id: string) => void;
  /** Accessible name for the menu. */
  ariaLabel?: string;
  node?: string;
  className?: string;
}

export function MxMenu(props: MxMenuProps): JSX.Element;
