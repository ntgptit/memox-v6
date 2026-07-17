export interface MxSwitchProps {
  checked?: boolean;
  /** Truly disables the control: sets the button `disabled` and blocks `onChange`. */
  disabled?: boolean;
  onChange?: (next: boolean) => void;
  node?: string;
  /** Accessible label (the switch has no visible text). Strongly recommended. */
  ariaLabel?: string;
}

/** Binary on/off toggle with a growing thumb. Base class `switch`. */
export function MxSwitch(props: MxSwitchProps): JSX.Element;
