export interface BarsProps {
  /** Bar values. */
  data: number[];
  /** X-axis labels (one per bar). */
  labels: string[];
  /** Bar color. Omit for the primary base. Flutter names this `color`. */
  tone?: string;
}

/** Statistics simple vertical bar chart (weekly + Leitner). */
export function Bars(props: BarsProps): JSX.Element;
