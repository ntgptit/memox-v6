export interface StageGuessProps {
  /**
   * Relearn stage — shows the "not counted toward progress" note. In Flutter the
   * not-counted note is driven by the `wrong` pick state instead of a flag
   * (recorded as a flutter-idiom exception).
   */
  relearn?: boolean;
}

/**
 * Study-session stage 3 / relearn: a prompt term with multiple-choice options.
 * The kit hardcodes the term + choices as a fixture; the Flutter `StageGuess`
 * parameterizes term / choices / correctChoice / chosen / wrong and wires
 * `onChoose` — recorded as fixture-parameterized exceptions.
 */
export function StageGuess(props: StageGuessProps): JSX.Element;
