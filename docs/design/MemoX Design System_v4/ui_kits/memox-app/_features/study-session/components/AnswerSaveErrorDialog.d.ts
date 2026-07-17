/**
 * Study-session answer-save-error overlay — composes the shared ConfirmDialog with
 * a fixed icon/title/text and Back / Retry actions.
 *
 * The kit renders this as a **static fixture** (hardcoded copy + node ids) and
 * exposes **no props**. In Flutter it is a `show()` helper
 * (`AnswerSaveErrorDialog.show(context) → AnswerSaveErrorChoice?`), not a widget
 * constructor — so there is no prop surface to diff.
 */
export interface AnswerSaveErrorDialogProps {}

export function AnswerSaveErrorDialog(): JSX.Element;
