import React from 'react';

/* MxAvatar — user / entity avatar. Base class: avatar */
export function MxAvatar({ name, src, size, variant, ring = false, node }) {
  const cls = ['avatar'];
  if (size && size !== 'md') cls.push('avatar--' + size);
  if (variant) cls.push('avatar--' + variant);
  if (ring) cls.push('avatar--ring');
  const initials = name ? name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase() : '';
  return (
    <span className={cls.join(' ')} data-mx-node={node}>
      {src ? <img src={src} alt={name || ''} /> : initials}
    </span>
  );
}
