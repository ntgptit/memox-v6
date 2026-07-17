import type { ReactNode } from 'react';

export interface OnboardingHeroProps {
  /** Material Symbols name for the hero glyph. */
  icon: string;
  /** Headline naming the space ("Start your first deck"). */
  title: string;
  /** One-line body explaining it. */
  text: string;
  /** CTA stack (Create a deck / Import from a file). Flutter names this slot `child`. */
  children?: ReactNode;
}

/** Dashboard first-run hero card (kit `dashboard/onboarding`): invitation to create the first deck. */
export function OnboardingHero(props: OnboardingHeroProps): JSX.Element;
