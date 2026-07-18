/* MemoX — Languages local: RemoveLanguageDialog (remove-pair overlays).
   Composes the shared window.ConfirmDialog (_shared/ConfirmDialog.jsx).
   Removal semantics follow ADR-008 / business remove-language-pair.md: a Pair with
   dependent Decks is BLOCKED (no cascade delete); only a zero-dependency Pair may be
   removed, and the confirm copy must not claim any Deck or Card is deleted. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

/* Zero-dependency Pair: safe destructive confirm. No Deck/Card is affected. */
function RemoveLanguageDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="languages/remove-scrim"
      icon="delete" tone="error" title="Remove Français → English?"
      text="This language pair has no decks. Removing it can't be undone."
      dialogNode="languages/remove-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="languages/remove-cancel">Cancel</MxButton>
        <MxButton variant="primary" danger block node="languages/remove-ok">Remove</MxButton>
      </React.Fragment>} />
  );
}

/* Dependency-blocked Pair: removal is blocked; route the user to manage the Decks
   first. No destructive action is offered here (ADR-008). */
function RemoveLanguageBlockedDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="languages/remove-blocked-scrim"
      icon="folder" tone="warning" title="Move or delete decks first"
      text="This pair still has 3 decks. Language pairs with decks can't be removed — its decks and cards are kept. Manage those decks first, then remove the pair."
      dialogNode="languages/remove-blocked-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="languages/remove-blocked-cancel">Cancel</MxButton>
        <MxButton variant="primary" block node="languages/remove-blocked-manage">Manage decks</MxButton>
      </React.Fragment>} />
  );
}

window.MemoXLanguages = window.MemoXLanguages || {};
window.MemoXLanguages.RemoveLanguageDialog = RemoveLanguageDialog;
window.MemoXLanguages.RemoveLanguageBlockedDialog = RemoveLanguageBlockedDialog;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const RemoveLanguageDialog = (window.MemoXLanguages || {}).RemoveLanguageDialog;
export const RemoveLanguageBlockedDialog = (window.MemoXLanguages || {}).RemoveLanguageBlockedDialog;
