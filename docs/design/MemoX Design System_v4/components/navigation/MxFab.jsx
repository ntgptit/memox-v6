import React from 'react';

/* MxFab — floating action button. Base class: fab.
   Icon-only FABs (no visible `label`) MUST be given `ariaLabel` for an accessible name. */
export function MxFab({ icon, label, variant, round = false, ariaLabel, disabled = false, node, onClick }) {
  const cls = ['fab'];
  if (variant) cls.push('fab--' + variant);
  if (round || !label) cls.push('fab--round');
  return (
    <button type="button" className={cls.join(' ')} data-mx-node={node} onClick={onClick}
      disabled={disabled} aria-label={ariaLabel || (!label ? icon : undefined)}>
      {icon ? <span className="material-symbols-rounded" aria-hidden="true">{icon}</span> : null}
      {label ? <span>{label}</span> : null}
    </button>
  );
}
