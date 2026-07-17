/**
 * Bare inline text input — borderless and token-styled, for editable text inside a
 * feature surface (editor fields, game answers, paste boxes). The visible box, if
 * any, belongs to the surrounding container; this component is only the input.
 * @startingPoint section="Core" subtitle="Text field — bare inline input" viewport="320x120"
 */
export interface MxTextFieldProps {
  value?: string;
  defaultValue?: string;
  placeholder?: string;
  /** Visible label — renders a `<label>` wired to the input via `htmlFor`/`id`. */
  label?: string;
  /** Helper text under the field (hidden when `error` is set). */
  helper?: string;
  /** Error message — sets the error state, `aria-invalid`, and `role="alert"`. */
  error?: string;
  /** Renders a multi-line textarea instead of a single-line input. */
  multiline?: boolean;
  /** Minimum visible rows when `multiline`. */
  rows?: number;
  /** Horizontal alignment of the text and placeholder. */
  align?: 'start' | 'center';
  autoFocus?: boolean;
  /** Input type (single-line only): text, email, password, number, tel, url… */
  type?: string;
  /** Virtual-keyboard hint: numeric, decimal, email, tel, search, url. */
  inputMode?: string;
  disabled?: boolean;
  /** Read-only: value is shown and focusable/selectable but not editable (distinct from `disabled`). */
  readOnly?: boolean;
  required?: boolean;
  id?: string;
  name?: string;
  /** Accessible name when there is no visible `label` (falls back to `placeholder`). */
  ariaLabel?: string;
  node?: string;
  className?: string;
  onChange?: (event: unknown) => void;
}

export function MxTextField(props: MxTextFieldProps): JSX.Element;
