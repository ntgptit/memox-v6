import React from 'react';

/* MxBottomNav — bottom tab bar. Base class: bottom-nav */
export function MxBottomNav({ items = [], value, onChange, node }) {
  return (
    <nav className="bottom-nav" data-mx-node={node}>
      {items.map((it) => {
        const active = it.id === value;
        return (
          <button
            key={it.id}
            type="button"
            aria-current={active ? 'page' : undefined}
            className={['bottom-nav__item', active ? 'bottom-nav__item--active' : ''].filter(Boolean).join(' ')}
            onClick={() => onChange && onChange(it.id)}
          >
            <span className="bottom-nav__icon"><span className="material-symbols-rounded">{it.icon}</span></span>
            <span>{it.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
