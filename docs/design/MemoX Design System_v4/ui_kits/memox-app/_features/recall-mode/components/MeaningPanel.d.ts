export interface MeaningPanelProps {
  /**
   * Whether the meaning is revealed. `false` (the base) shows the recall hint;
   * `true` shows the meaning. The kit hardcodes the sample meaning text as a
   * fixture — the Flutter `MeaningPanel` parameterizes it via `meaning` (String),
   * recorded as a `fixture-parameterized` exception.
   */
  revealed?: boolean;
}

/** Game-recall meaning panel: a recall hint until `revealed`, then the meaning. */
export function MeaningPanel(props: MeaningPanelProps): JSX.Element;
