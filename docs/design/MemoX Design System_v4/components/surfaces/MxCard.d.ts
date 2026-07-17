import type { ReactNode, CSSProperties } from 'react';

/**
 * The primary content surface — elevated by default; flat/muted/primary variants.
 * @startingPoint section="Surfaces" subtitle="Rounded content surface with variants" viewport="360x180"
 */
export interface MxCardProps {
  /** Surface treatment. `elevated` is the base (omit the prop). @default 'elevated' */
  variant?: 'elevated' | 'flat' | 'muted' | 'primary' | 'primary-soft';
  /** Adds hover/press affordance. */
  interactive?: boolean;
  /** Padding step. `md` is the base (omit the prop). @default 'md' */
  padding?: 'sm' | 'md' | 'lg';
  node?: string;
  className?: string;
  children?: ReactNode;
  onClick?: () => void;
  style?: CSSProperties;
}

export function MxCard(props: MxCardProps): JSX.Element;
