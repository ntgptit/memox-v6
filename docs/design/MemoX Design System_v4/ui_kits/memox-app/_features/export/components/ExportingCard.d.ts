/**
 * Export in-progress card: a spinner + "Exporting…" + a progress bar.
 *
 * The kit renders this as a **static fixture** (hardcoded progress) and exposes
 * **no props**. The Flutter `ExportingCard` is likewise self-contained
 * (`const ExportingCard()`) — so both sides expose no props.
 */
export interface ExportingCardProps {}

export function ExportingCard(): JSX.Element;
