import type { ReactNode } from 'react';

export interface PromptCardProps {
  /** The centered prompt term. */
  term: ReactNode;
  /** Optional sub-label above/below the term (e.g. "MEANING"). */
  sub?: ReactNode;
}

/** Study-session prompt card: a centered term with an optional sub-label. Shared by StageGuess / StageRecall / StageFill. */
export function PromptCard(props: PromptCardProps): JSX.Element;
