import type { ReactNode } from 'react';

export interface TodaySummaryProps {
  /** Time studied today (formatted). */
  time: ReactNode;
  /** Words learned today. */
  words: ReactNode;
  /** Optional CTA slot (currently unused — first-run renders OnboardingHero). Flutter names this slot `action`. */
  children?: ReactNode;
}

/** Dashboard "Today" hero card: time + words, with an optional Start CTA. */
export function TodaySummary(props: TodaySummaryProps): JSX.Element;
