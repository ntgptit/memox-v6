/* MxDialog — the ONE centered modal decision surface. Base class: dialog.
   A blocking, focus-trapped surface for a single decision (confirm / discard /
   name-this): a scrim over the app, a raised panel holding title + body + actions.
   Content is passed by slot; the panel never carries screen-specific chrome.

   Focus-trap contract (documented, enforced by the host app / RN Modal):
     - On open, focus moves to the panel (tabIndex=-1); Tab cycles ONLY within it.
     - Escape and scrim tap call onDismiss when `dismissible` (default true).
     - On close, focus returns to the element that opened the dialog.
     - role="dialog" + aria-modal="true"; the title is wired via aria-labelledby.

   Runtime-authored (IIFE + global React) so the kit gallery can load it via
   <script type="text/babel-src"> without a bundle rebuild; ESM-exported too. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});
  const R = window.React;

  function MxDialog(props) {
    const {
      open = true, title, children, actions, dismissible = true,
      onDismiss, node, className = '', ariaLabel,
    } = props;

    const panelRef = R.useRef(null);
    const titleId = R.useId ? R.useId() : undefined;

    // Move focus into the panel on open so the trap has an anchor, and wire Escape
    // to dismiss. (No pixels change — focus + key handling only.)
    R.useEffect(() => {
      if (!open || !panelRef.current) return;
      panelRef.current.focus();
      const onKey = (e) => { if (e.key === 'Escape' && dismissible && onDismiss) onDismiss(); };
      document.addEventListener('keydown', onKey);
      return () => document.removeEventListener('keydown', onKey);
    }, [open, dismissible]);

    if (!open) return null;

    const cls = ['dialog', className].filter(Boolean).join(' ');
    return (
      <div className="dialog-layer" data-mx-node={node}>
        <div className="dialog__scrim" onClick={dismissible ? onDismiss : undefined} aria-hidden="true" />
        <div
          ref={panelRef}
          className={cls}
          role="dialog"
          aria-modal="true"
          aria-label={title ? undefined : ariaLabel}
          aria-labelledby={title ? titleId : undefined}
          tabIndex={-1}
        >
          {title ? <div className="dialog__title" id={titleId}>{title}</div> : null}
          {children ? <div className="dialog__body">{children}</div> : null}
          {actions ? <div className="dialog__actions">{actions}</div> : null}
        </div>
      </div>
    );
  }

  NS.MxDialog = MxDialog;
})();

export const MxDialog = (window.MemoXDesignSystem_2ffa54 || {}).MxDialog;
