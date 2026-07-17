import React from 'react';

/* MxIconTile — rounded color tile holding a glyph. Base class: icon-tile */
export function MxIconTile({ icon, tone, size, solid = false, node, className = '' }) {
  const cls = ['icon-tile'];
  if (tone) cls.push('icon-tile--' + tone);
  if (size === 'lg') cls.push('icon-tile--lg');
  if (solid) cls.push('icon-tile--solid');
  if (className) cls.push(className);
  return (
    <span className={cls.join(' ')} data-mx-node={node}>
      <span className="material-symbols-rounded">{icon}</span>
    </span>
  );
}
