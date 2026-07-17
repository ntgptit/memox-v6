import React from 'react';

/* MxIconButton — icon-only button. Base class: icon-btn */
export function MxIconButton({ icon, variant, size, node, className = '', onClick, ariaLabel, disabled = false }) {
  const cls = ['icon-btn'];
  if (variant && variant !== 'plain') cls.push('icon-btn--' + variant);
  if (size === 'sm') cls.push('icon-btn--sm');
  if (className) cls.push(className);
  return (
    <button type="button" className={cls.join(' ')} data-mx-node={node} onClick={onClick} aria-label={ariaLabel || icon} disabled={disabled}>
      <span className="material-symbols-rounded">{icon}</span>
    </button>
  );
}
