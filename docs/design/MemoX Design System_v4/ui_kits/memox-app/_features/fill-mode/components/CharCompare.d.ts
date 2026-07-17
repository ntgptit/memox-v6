/**
 * Game-typing per-character diff: each glyph of the typed answer tinted success
 * when it matches the correct term, error otherwise; a never-typed slot shows `_`.
 *
 * The kit renders this as a **static fixture** — it hardcodes the sample
 * typed/correct pair (친고 vs 친구) so the parity generator captures real DOM, so
 * it exposes **no props**. The Flutter `CharCompare` parameterizes the fixtured
 * content: `typed` + `correct` (String) — recorded as `fixture-parameterized`
 * exceptions.
 */
export interface CharCompareProps {}

export function CharCompare(): JSX.Element;
