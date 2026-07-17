/**
 * Study-session full-screen resume-error state (own app bar, no progress bar):
 * an EmptyState with Restart session / Back to deck actions.
 *
 * The kit renders this as a **static fixture** (hardcoded copy + node ids) and
 * exposes **no props**. The Flutter `ResumeErrorState` wires the real
 * `onRestart` / `onBack` callbacks — recorded as fixture-parameterized exceptions.
 */
export interface ResumeErrorStateProps {}

export function ResumeErrorState(): JSX.Element;
