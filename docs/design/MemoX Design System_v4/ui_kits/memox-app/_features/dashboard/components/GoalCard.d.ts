export interface GoalCardProps {
  /** Progress-ring percentage (0–100). Flutter names this `percent`. */
  pct: number;
  /**
   * Whether the goal is met — toggles the summary line. The kit hardcodes the
   * minutes/words values; Flutter parameterizes them (`goal` / `minutes` /
   * `words`) — recorded as fixture-parameterized exceptions.
   */
  met?: boolean;
}

/** Dashboard daily-goal card: a progress ring beside the goal summary. */
export function GoalCard(props: GoalCardProps): JSX.Element;
