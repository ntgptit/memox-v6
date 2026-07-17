import type { ReactNode } from 'react';

export interface LangCardProps {
  /** Leading icon (Material Symbols Rounded ligature name). */
  icon: string;
  /** Language name. */
  name: ReactNode;
  /** Sub-label (Flutter names this `subtitle`). */
  sub: ReactNode;
  node?: string;
}

/** Language row: a learning/native language in the add-pair form. */
export function LangCard(props: LangCardProps): JSX.Element;
