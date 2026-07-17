/**
 * Study-session leave-session confirm overlay — composes the shared ConfirmDialog
 * with a fixed icon/title/text and Stay / Leave actions.
 *
 * The kit renders this as a **static fixture** (hardcoded copy + node ids) and
 * exposes **no props**. In Flutter it is a `show()` helper
 * (`ExitDialog.show(context) → bool?`), not a widget constructor — so there is no
 * prop surface to diff.
 */
export interface ExitDialogProps {}

export function ExitDialog(): JSX.Element;
