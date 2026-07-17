import type { ReactNode } from 'react';

export interface FieldProps {
  /** Field label. */
  label: ReactNode;
  /** Current value; falls back to `placeholder` when empty. */
  value?: ReactNode;
  /** Placeholder shown when `value` is empty. */
  placeholder?: ReactNode;
  /** Taller multiline field. */
  multiline?: boolean;
  /** Error message — also tints the border. */
  error?: ReactNode;
  /** Show the required `*` marker. */
  required?: boolean;
  node?: string;
  /** Optional trailing slot. */
  trailing?: ReactNode;
}

/**
 * Flashcard-editor labeled text field (optional error / trailing). In Flutter the
 * field is edited via a `controller` + `onChanged` (recorded as flutter-idiom
 * exceptions); everything else maps directly.
 */
export function Field(props: FieldProps): JSX.Element;
