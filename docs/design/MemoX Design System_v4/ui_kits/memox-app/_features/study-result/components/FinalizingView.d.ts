import type { ReactNode } from 'react';

export interface FinalizingViewProps {
  /** The scaffold app bar (a pre-rendered node in the kit). */
  bar?: ReactNode;
  /** Reframe as a re-attempt after a finalize error (Retrying… vs Saving…). */
  retry?: boolean;
}

/**
 * Study-result "saving your results…" view shown while the session commits to
 * SRS. The kit passes a pre-rendered `bar` node; the Flutter `FinalizingView`
 * builds its own `MxContextualAppBar` and takes an `onClose` callback for the close action
 * — recorded as exceptions.
 */
export function FinalizingView(props: FinalizingViewProps): JSX.Element;
