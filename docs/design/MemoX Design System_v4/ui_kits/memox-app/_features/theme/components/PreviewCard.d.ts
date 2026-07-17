export interface PreviewCardProps {
  /** Term font size (CSS length). Flutter uses a `fontScale` factor instead. */
  termSize: string;
  /** Accent color for the CTA. Flutter names this `accent`. */
  accentColor: string;
}

/**
 * Theme live preview card (term / meaning / CTA). The preview sample text is
 * hardcoded on both sides; only the theme knobs are parameterized. In Flutter
 * `termSize` is a `fontScale` factor and `accentColor` is `accent` — recorded as
 * exceptions.
 */
export function PreviewCard(props: PreviewCardProps): JSX.Element;
