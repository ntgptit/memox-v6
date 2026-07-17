import type { ReactNode } from 'react';

export interface ResultRowProps {
  /** Term / headword. */
  term: ReactNode;
  /** Meaning / translation. */
  meaning: ReactNode;
  /** Deck line (search shows the owning deck). */
  deck?: ReactNode;
  /** Learning status — drives the trailing badge. */
  status: 'new' | 'due' | 'mastered';
  /** Dim the row and show a hidden glyph. */
  hidden?: boolean;
  onClick?: () => void;
}

/**
 * Search result row: forwards the shared StatusCardRow props (with the search
 * `deck` line, untightened). In Flutter these fields are composed into a single
 * `result` model — recorded as flutter-idiom exceptions.
 */
export function ResultRow(props: ResultRowProps): JSX.Element;
