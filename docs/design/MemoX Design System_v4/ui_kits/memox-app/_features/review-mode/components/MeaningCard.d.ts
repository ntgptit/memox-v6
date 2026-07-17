export interface MeaningCardProps {
  /**
   * Whether the meaning is in edit mode. `false` (base) shows the read-only value;
   * `true` shows a bordered field with Cancel / Save.
   */
  editing?: boolean;
}

/**
 * Review meaning card with an inline edit affordance. The kit hardcodes the
 * sample meaning (school) as a fixture and stubs the edit / cancel / save buttons
 * with node ids; the Flutter `MeaningCard` parameterizes the content (`meaning`),
 * wires the real `onEdit`/`onCancel`/`onSave` callbacks, and binds the edit field
 * to a `controller` — recorded as exceptions.
 */
export function MeaningCard(props: MeaningCardProps): JSX.Element;
