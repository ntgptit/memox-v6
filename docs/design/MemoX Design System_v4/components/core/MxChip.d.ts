import type { ReactNode } from 'react';

export interface MxChipProps {
  label?: ReactNode;
  /** Leading icon (Material Symbols name). */
  icon?: string;
  /** Selected (filled) state. */
  selected?: boolean;
  /** Unavailable / disabled: inert and dimmed. */
  disabled?: boolean;
  variant?: 'accent' | 'ghost';
  node?: string;
  onClick?: () => void;
  children?: ReactNode;
}

/** Filter / choice chip; outlined by default, tinted when `selected`. Base class `chip`. */
export function MxChip(props: MxChipProps): JSX.Element;
