/* MxSheet — the ONE bottom sheet. Base class: sheet.
   A surface that rises from the bottom edge for a set of options, a short form, or
   secondary content: a scrim, a drag handle, an optional title, and a scrollable body
   that caps its height and honours the bottom safe-area. Content is passed by slot.

   Dismissal / focus contract (documented, enforced by the host app / RN Modal):
     - Escape and scrim tap call onDismiss when `dismissible` (default true).
     - Focus moves into the sheet on open and returns to the opener on close.
     - role="dialog" + aria-modal="true"; the title is wired via aria-labelledby.

   Runtime-authored (IIFE + global React) so the kit gallery can load it via
   <script type="text/babel-src"> without a bundle rebuild; ESM-exported too. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});
  const R = window.React;

  function MxSheet(props) {
    const {
      open = true, title, children, maxHeight, dismissible = true,
      onDismiss, node, className = '', ariaLabel,
    } = props;

    const sheetRef = R.useRef(null);
    const titleId = R.useId ? R.useId() : undefined;

    R.useEffect(() => {
      if (!open || !sheetRef.current) return;
      sheetRef.current.focus();
      const onKey = (e) => { if (e.key === 'Escape' && dismissible && onDismiss) onDismiss(); };
      document.addEventListener('keydown', onKey);
      return () => document.removeEventListener('keydown', onKey);
    }, [open, dismissible]);

    if (!open) return null;

    const cls = ['sheet', className].filter(Boolean).join(' ');
    // maxHeight override is a layout ratio/length passed straight through (token-driven
    // when the caller supplies a token); the base class caps it otherwise.
    const style = maxHeight ? { maxHeight } : undefined;
    return (
      <div className="sheet-layer" data-mx-node={node}>
        <div className="sheet__scrim" onClick={dismissible ? onDismiss : undefined} aria-hidden="true" />
        <div
          ref={sheetRef}
          className={cls}
          style={style}
          role="dialog"
          aria-modal="true"
          aria-label={title ? undefined : ariaLabel}
          aria-labelledby={title ? titleId : undefined}
          tabIndex={-1}
        >
          <div className="sheet__handle" aria-hidden="true" />
          {title ? <div className="sheet__title" id={titleId}>{title}</div> : null}
          <div className="sheet__body">{children}</div>
        </div>
      </div>
    );
  }

  NS.MxSheet = MxSheet;
})();

export const MxSheet = (window.MemoXDesignSystem_2ffa54 || {}).MxSheet;
