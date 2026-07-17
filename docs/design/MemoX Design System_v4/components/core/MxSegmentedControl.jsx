import React from 'react';

/* MxSegmentedControl — segmented toggle. Base class: segmented */
export function MxSegmentedControl({ segments = [], value, onChange, block = false, node }) {
  const cls = ['segmented'];
  if (block) cls.push('segmented--block');
  return (
    <div className={cls.join(' ')} data-mx-node={node} role="radiogroup">
      {segments.map((s) => {
        const v = typeof s === 'string' ? s : s.value;
        const label = typeof s === 'string' ? s : s.label;
        const icon = typeof s === 'object' ? s.icon : null;
        const disabled = typeof s === 'object' ? !!s.disabled : false;
        const active = v === value;
        return (
          <button key={v} type="button" role="radio" aria-checked={active} aria-label={label} disabled={disabled} aria-disabled={disabled || undefined} data-mx-node={node ? `${node}/${v}` : undefined} className={['segmented__seg', active ? 'segmented__seg--active' : ''].filter(Boolean).join(' ')} onClick={() => { if (!disabled && onChange) onChange(v); }}>
            {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
            {label}
          </button>
        );
      })}
    </div>
  );
}
