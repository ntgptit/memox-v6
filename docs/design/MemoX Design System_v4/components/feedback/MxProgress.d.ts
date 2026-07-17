/**
 * The one progress indicator — determinate or indeterminate, as a linear bar or an
 * inline spinner. Base class `progress`.
 * @startingPoint section="Feedback" subtitle="Progress — determinate bar + indeterminate spinner" viewport="320x120"
 *
 * Accessibility:
 * - role="progressbar"; when `value` is a number it sets aria-valuemin=0 /
 *   aria-valuemax=100 / aria-valuenow. Indeterminate omits aria-valuenow.
 * - `ariaLabel` names the task (defaults to "Loading").
 * - Reduced motion: the sliding fill and the spinner honour prefers-reduced-motion
 *   (animation settles via --memox-duration-none).
 */
export interface MxProgressProps {
  /** Form. `bar` is a linear track; `spinner` is an inline circular indicator. @default 'bar' */
  variant?: 'bar' | 'spinner';
  /** 0–100 → determinate. Omit for indeterminate (sliding bar / spinning ring). */
  value?: number;
  /** Accessible name for the task. @default 'Loading' */
  ariaLabel?: string;
  node?: string;
  className?: string;
}

export function MxProgress(props: MxProgressProps): JSX.Element;
