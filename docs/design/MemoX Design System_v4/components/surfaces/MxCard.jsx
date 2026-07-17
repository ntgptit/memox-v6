import React from 'react';

/* MxCard — surface container. Base class: card */
export function MxCard({ variant, interactive = false, padding, node, className = '', children, onClick, style, ariaLabel }) {
  const cls = ['card'];
  if (variant && variant !== 'elevated') cls.push('card--' + variant);
  if (interactive) cls.push('card--interactive');
  if (padding && padding !== 'md') cls.push('card--pad-' + padding);
  if (className) cls.push(className);
  // When the card is actionable, give it real button semantics + keyboard
  // support (Enter/Space) without changing the tag (keeps the visual identical).
  const actionable = typeof onClick === 'function';
  const a11y = actionable
    ? { role: 'button', tabIndex: 0, 'aria-label': ariaLabel, onKeyDown: (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onClick(e); } } }
    : {};
  return (
    <div className={cls.join(' ')} data-mx-node={node} onClick={onClick} style={style} {...a11y}>
      {children}
    </div>
  );
}
