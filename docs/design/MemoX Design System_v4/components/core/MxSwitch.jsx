import React from 'react';

/* MxSwitch — on/off toggle. Base class: switch */
export function MxSwitch({ checked = false, disabled = false, onChange, node, ariaLabel }) {
  const cls = ['switch'];
  if (checked) cls.push('switch--on');
  if (disabled) cls.push('switch--disabled');
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={ariaLabel}
      disabled={disabled}
      className={cls.join(' ')}
      data-mx-node={node}
      onClick={() => { if (disabled) return; onChange && onChange(!checked); }}
    >
      <span className="switch__thumb" />
    </button>
  );
}
