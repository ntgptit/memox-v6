import type { ReactNode } from 'react';

export interface StatusCardRowProps {
  /** Term / headword. */
  term: ReactNode;
  /** Meaning / translation. */
  meaning: ReactNode;
  /** Optional deck line — search shows the owning deck; flashcard-list omits it. */
  deck?: ReactNode;
  /** Learning status — drives the trailing badge (label from ARB). */
  status: 'new' | 'due' | 'mastered';
  /** Dim the row and show a hidden glyph. */
  hidden?: boolean;
  node?: string;
  onClick?: () => void;
  /** flashcard-list tightens the term letter-spacing. */
  tightTerm?: boolean;
  /** flashcard-list clips the meaning to one line. */
  truncateMeaning?: boolean;
}

/**
 * Term + meaning (+ optional deck line) with a trailing status badge. Owns the
 * single new/due/mastered taxonomy shared by flashcard-list the Flashcard List + search
 * ResultRow (previously duplicated). Wrap it in an `MxCard` at the call site.
 */
export function StatusCardRow(props: StatusCardRowProps): JSX.Element;
