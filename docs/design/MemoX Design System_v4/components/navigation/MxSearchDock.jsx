import React from 'react';

/* MxSearchDock — pill search field. Base class: search-dock */
export function MxSearchDock({ placeholder = 'Search', value, onChange, focused = false, flat = false, trailing, ariaLabel, node }) {
  const cls = ['search-dock'];
  if (focused) cls.push('search-dock--focused');
  if (flat) cls.push('search-dock--flat');
  return (
    <div className={cls.join(' ')} data-mx-node={node}>
      <span className="material-symbols-rounded" aria-hidden="true">search</span>
      <input className="search-dock__input" type="search" inputMode="search" placeholder={placeholder}
        value={value} onChange={onChange} aria-label={ariaLabel || placeholder} />
      {trailing}
    </div>
  );
}
