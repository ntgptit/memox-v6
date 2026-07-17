export interface OnboardingStepProps {
  /** Material Symbols name for the leading tile glyph. */
  icon: string;
  /** Tile tone (defaults to soft primary). */
  tone?: 'accent' | 'success' | 'warning' | 'error';
  /** Step headline ("Add your words"). */
  title: string;
  /** One-line caption explaining the step. */
  text: string;
  node?: string;
}

/** One "How MemoX works" step row on the first-run dashboard. */
export function OnboardingStep(props: OnboardingStepProps): JSX.Element;
