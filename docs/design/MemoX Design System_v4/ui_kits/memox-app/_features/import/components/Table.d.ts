import type { ReactNode } from 'react';

export interface TableProps {
  /** The preview rows (row 0 is the header); each row is a 2-cell array. */
  rows: ReactNode[][];
}

/** Import 2-column preview table (mapping + preview). In Flutter this is `ImportTable`. */
export function Table(props: TableProps): JSX.Element;
