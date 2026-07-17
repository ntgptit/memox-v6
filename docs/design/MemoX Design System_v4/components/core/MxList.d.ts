import type { ReactNode } from 'react';

export interface MxListProps {
  /** The stacked cards / rows. */
  children?: ReactNode;
  /** Gap between items — any spacing token; defaults to `var(--memox-space-3)` (12px). */
  gap?: string;
  node?: string;
}

/**
 * The one vertical list wrapper for any stack of cards (decks, subdecks, flashcards, search
 * results…). Owns the standard 12px inter-card gap so every list spaces items identically —
 * always wrap a card list in this instead of dropping cards into the scroll body (24px gap).
 */
export function MxList(props: MxListProps): JSX.Element;
