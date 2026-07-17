import type { ReactNode } from 'react';

export interface SelectSheetOption {
  /** React list key (stable per row). */
  key: string | number;
  /** Leading Material Symbols icon name. */
  icon: string;
  /** Row label (from ARB). */
  label: ReactNode;
  /** Stable `data-mx-node` id for this row (per-screen). */
  node?: string;
  /** Active option — renders the primary-tinted trailing check. */
  selected?: boolean;
  onClick?: () => void;
}

export interface SelectSheetProps {
  /** Uppercase section title (from ARB). */
  title?: ReactNode;
  /** `data-mx-node` id for the sheet surface. */
  node?: string;
  /** The rows; exactly one is typically `selected`. */
  options: SelectSheetOption[];
}

/**
 * Single-select option list inside a bottom `Sheet`. Owns the title + rows +
 * active-check pattern shared by mode-picker ScopeSheet, library SortSheet and
 * settings ValuePickerSheet. Wrap it in a `Scrim` at the call site when presenting
 * it as an overlay.
 */
export function SelectSheet(props: SelectSheetProps): JSX.Element;
