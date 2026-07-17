/* MxLink — text / navigation link button. Base class: link
   A lightweight "go somewhere" affordance (See all, Learn more, Manage…) — no filled
   or block button chrome. Renders a <button> by default, or an <a> when `href` is set.
   Colour is the bright `accent` token so it keeps contrast on light and dark surfaces;
   tap target is >=48px (min-height) even though the text is visually compact.

   NOTE: unlike the other core Mx* primitives this file is authored in the runtime
   (IIFE + global React) style so the kit gallery can load it directly via
   <script type="text/babel-src"> without a bundle rebuild; it still ESM-exports for the
   design-system compiler. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});

  function MxLink({ children, icon, trailingIcon = 'chevron_right', href, size, node, onClick, disabled = false, className = '' }) {
    const cls = ['link'];
    if (size) cls.push('link--' + size);
    if (className) cls.push(className);
    const Tag = href ? 'a' : 'button';
    // Disabled: a real `disabled` <button> (removed from the tab order, activation blocked); an <a>
    // link takes aria-disabled + tabIndex -1 since <a> has no disabled attribute.
    const extra = href
      ? { href, ...(disabled ? { 'aria-disabled': true, tabIndex: -1 } : {}) }
      : { type: 'button', disabled };
    return (
      <Tag className={cls.join(' ')} data-mx-node={node} onClick={disabled ? undefined : onClick} {...extra}>
        {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
        <span>{children}</span>
        {trailingIcon ? <span className="material-symbols-rounded">{trailingIcon}</span> : null}
      </Tag>
    );
  }

  NS.MxLink = MxLink;
})();

/* ESM export so the design-system compiler indexes this primitive. */
export const MxLink = (window.MemoXDesignSystem_2ffa54 || {}).MxLink;
