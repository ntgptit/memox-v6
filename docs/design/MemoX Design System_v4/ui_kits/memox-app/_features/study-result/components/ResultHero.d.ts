export interface ResultHeroProps {
  /** Icon tile glyph (Material Symbols Rounded ligature name). */
  icon: string;
  /** Icon tile tone. Omit for the soft-primary base. */
  tone?: 'accent' | 'success' | 'warning' | 'error';
  /** Hero title. */
  title: string;
  /** Hero subtitle. */
  text: string;
}

/**
 * Study-result hero: a large icon tile above a title + subtitle. Fully
 * parameterized (shared by the result summary and the finalizing view).
 */
export function ResultHero(props: ResultHeroProps): JSX.Element;
