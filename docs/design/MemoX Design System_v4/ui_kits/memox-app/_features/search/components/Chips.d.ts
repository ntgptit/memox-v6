export interface ChipsProps {
  /** Index of the active filter (All / New / Due / Mastered). */
  active: number;
}

/**
 * Search status-filter chip row. The kit hardcodes the filter labels + stubs the
 * chips with node ids; the Flutter `SearchChips` wires `onSelect` — recorded as a
 * fixture-parameterized exception.
 */
export function Chips(props: ChipsProps): JSX.Element;
