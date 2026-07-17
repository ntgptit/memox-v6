/**
 * Remove-language-pair confirm overlay — composes the shared ConfirmDialog.
 *
 * The kit renders this as a **static fixture** (hardcoded copy + node ids) and
 * exposes **no props**. In Flutter it is the top-level helper
 * `showRemoveLanguageDialog(context, …) → Future<bool>` — a function, not a widget
 * class — so there is no constructor to diff (recorded as a flutter-helper
 * exception).
 */
export interface RemoveLanguageDialogProps {}

export function RemoveLanguageDialog(): JSX.Element;
