import React from 'react';

/* MxBadge — count / status badge. Base class: badge */
export function MxBadge({ children, tone, soft = false, dot = false, node }) {
  const cls = ['badge'];
  if (tone) cls.push('badge--' + tone);
  if (soft) cls.push('badge--soft');
  if (dot) cls.push('badge--dot');
  return <span className={cls.join(' ')} data-mx-node={node}>{dot ? null : children}</span>;
}
