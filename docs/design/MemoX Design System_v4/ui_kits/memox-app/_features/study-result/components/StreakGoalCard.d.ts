export interface StreakGoalCardProps {
  /**
   * Whether today's goal was met — the kit fixture toggles between two hardcoded
   * sample states (12 vs 13 days, 14/20 vs 20/20 min). Flutter parameterizes the
   * real streak/goal values (streakLabel / streakCaption / goalLabel / goalValue
   * / goalPercent) — recorded as fixture-parameterized exceptions.
   */
  met?: boolean;
}

/** Study-result streak + today's-goal progress, on a primary-soft card. */
export function StreakGoalCard(props: StreakGoalCardProps): JSX.Element;
