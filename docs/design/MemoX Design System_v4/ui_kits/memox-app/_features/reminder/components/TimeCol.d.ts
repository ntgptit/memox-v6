export interface TimeColProps {
  /** The values shown in the column (hours or minutes). */
  values: string[];
  /** The selected value (Flutter names this `selected`). */
  sel: string;
}

/**
 * Reminder time-picker column (one scrollable hour/minute list). In Flutter the
 * tap is wired via `onSelect` and an accessible `semanticLabel` is added —
 * recorded as exceptions.
 */
export function TimeCol(props: TimeColProps): JSX.Element;
