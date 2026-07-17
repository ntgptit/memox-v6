/**
 * Player card: the current term + meaning being read aloud, separated by a rule.
 *
 * The kit renders this as a **static fixture** — it hardcodes the sample term
 * (학교) / meaning (school) so the parity generator captures real DOM. It
 * therefore exposes **no props**. The Flutter `PlayerCard` parameterizes the
 * content: `term` + `meaning` (String) — recorded as `fixture-parameterized`
 * exceptions.
 */
export interface PlayerCardProps {}

export function PlayerCard(): JSX.Element;
