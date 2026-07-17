/**
 * Mode-picker card-source selector: opens the source sheet, showing the current
 * source label.
 *
 * The kit renders this as a **static fixture** — it hardcodes the sample label
 * ("Card source" / "By schedule") and a literal `node` id so the parity generator
 * captures real DOM. It therefore exposes **no props**. The Flutter `ScopeCard`
 * parameterizes it: `sourceLabel` (String) + the real `onPressed` — recorded as
 * `fixture-parameterized` exceptions.
 */
export interface ScopeCardProps {}

export function ScopeCard(): JSX.Element;
