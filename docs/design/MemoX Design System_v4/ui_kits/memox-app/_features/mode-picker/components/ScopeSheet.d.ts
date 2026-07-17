/**
 * Mode-picker card-source sheet: By schedule / All cards / Unlearned only, with a
 * check on the active source; each item dismisses the sheet before applying.
 *
 * The kit renders this as a **static fixture** — it hardcodes the option list +
 * the selected option so the parity generator captures real DOM. It therefore
 * exposes **no props**. The Flutter `ScopeSheet` parameterizes the state:
 * `selected` (GameSource) + `onSelect` — recorded as `fixture-parameterized`
 * exceptions.
 */
export interface ScopeSheetProps {}

export function ScopeSheet(): JSX.Element;
