export interface CtaProps {
  /**
   * Which result the CTA pair is for. Omit for the standard result (Keep
   * studying / Back to library); `goal-missed` shows Keep going / Later.
   * `many-wrong` shows a "Review N cards" primary — see the note in
   * props-parity.exceptions.json: Flutter's `ResultHead` has no `many-wrong`
   * equivalent yet.
   */
  state?: 'goal-missed' | 'many-wrong';
}

/**
 * Study-result action pair (primary + secondary), which varies by result state.
 * The kit hardcodes the button labels + stubs them with node ids; Flutter models
 * the state as a `ResultHead` enum (`head`) and wires the real `onPrimary` /
 * `onSecondary` callbacks — recorded as exceptions.
 */
export function Cta(props: CtaProps): JSX.Element;
