/* MemoX shared composite: ConfirmDialog — a centered Scrim + Dialog confirm
   overlay. Used by 6 sites across study-session / deck-settings / languages, so it
   lives in _shared/ (≥2 screens) rather than any one feature. Thin wrapper over
   the window.Scrim + window.Dialog helpers; carries no copy of its own — every
   string + node id + action is passed in by the caller. */
(function () {

function ConfirmDialog({ align = 'center', scrimNode, icon, tone, title, text, dialogNode, actions }) {
  return (
    <window.Scrim align={align} node={scrimNode}>
      <window.Dialog icon={icon} tone={tone} title={title} text={text} node={dialogNode} actions={actions} />
    </window.Scrim>
  );
}

window.ConfirmDialog = ConfirmDialog;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ConfirmDialog = window.ConfirmDialog;
