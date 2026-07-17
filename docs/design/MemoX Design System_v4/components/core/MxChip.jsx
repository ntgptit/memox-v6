import React from 'react';

/* MxChip — filter / choice chip. Base class: chip */
export function MxChip({ label, icon, selected = false, disabled = false, variant, node, onClick, children }) {
  const cls = ['chip'];
  if (selected) cls.push('chip--selected');
  if (disabled) cls.push('chip--disabled');
  if (variant) cls.push('chip--' + variant);
  return (
    <button type="button" className={cls.join(' ')} data-mx-node={node} disabled={disabled} aria-disabled={disabled || undefined} onClick={disabled ? undefined : onClick}>
      {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
      {label || children}
    </button>
  );
}
