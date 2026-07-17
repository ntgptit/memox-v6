/**
 * Export-format radio list (CSV / Excel / Copy text).
 *
 * The kit renders this as a **static fixture** (hardcoded FORMATS + selection)
 * and exposes **no props**. The Flutter `FormatList` parameterizes `selected` and
 * wires `onSelect` — recorded as fixture-parameterized exceptions.
 */
export interface FormatListProps {}

export function FormatList(): JSX.Element;
