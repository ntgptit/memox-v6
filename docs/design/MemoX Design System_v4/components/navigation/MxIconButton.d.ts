export interface MxIconButtonProps {
  /** Material Symbols Rounded ligature name. */
  icon: string;
  /** Emphasis. `plain` is the base (omit the prop). @default 'plain' */
  variant?: 'plain' | 'filled' | 'primary';
  size?: 'sm';
  node?: string;
  className?: string;
  onClick?: () => void;
  /**
   * Accessible label — REQUIRED. The button has no visible text; a screen reader
   * must not fall back to the raw icon ligature (e.g. "arrow_back", "more_horiz").
   * Use a human label: "Back", "Close", "More options", "Play audio", "Clear search".
   */
  ariaLabel: string;
}

/** Icon-only round button for app-bar & toolbar actions. Base class `icon-btn`. */
export function MxIconButton(props: MxIconButtonProps): JSX.Element;
