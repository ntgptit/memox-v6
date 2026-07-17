/**
 * Player deck-progress indicator: a row of dots, filled + the active one
 * elongated up to the current position, the rest sunken.
 *
 * The kit renders this as a **static fixture** — it hardcodes the dot count (8)
 * and the active index (3) so the parity generator captures real DOM. It
 * therefore exposes **no props**. The Flutter `Dots` parameterizes the state:
 * `active` (int) — recorded as a `fixture-parameterized` exception.
 */
export interface DotsProps {}

export function Dots(): JSX.Element;
