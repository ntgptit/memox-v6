export interface DonutProps {
  /** Accuracy percentage (0–100). Flutter names this `percent`. */
  pct: number;
}

/**
 * Statistics accuracy ring. The kit hardcodes the "accuracy" caption; Flutter
 * takes it as a `label` param (recorded as a fixture-parameterized exception).
 */
export function Donut(props: DonutProps): JSX.Element;
