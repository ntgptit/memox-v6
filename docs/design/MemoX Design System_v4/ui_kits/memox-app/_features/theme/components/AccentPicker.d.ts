export interface AccentPickerProps {
  /** The accent-color palette (swatch list). Flutter defines this internally. */
  swatches: string[];
  /** Index of the selected accent. Flutter names this `selected`. */
  accent: number;
}

/**
 * Theme accent-color swatch grid. In Flutter the palette is defined internally
 * (not a param), the selected index is `selected`, and the tap is wired via
 * `onSelect` — recorded as exceptions.
 */
export function AccentPicker(props: AccentPickerProps): JSX.Element;
