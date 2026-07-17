import React from 'react';

/* MxScaffold — phone app shell. Base class: app */
export function MxScaffold({ appBar, bottomNav, fab, children, flush = false, node, className = '', style }) {
  return (
    <div className={['app', className].filter(Boolean).join(' ')} data-mx-node={node} style={style}>
      {appBar}
      <div className={['app__body', flush ? 'app__body--flush' : '', fab ? 'app__body--with-fab' : ''].filter(Boolean).join(' ')}>
        {children}
      </div>
      {fab ? (
        <div style={{ position: 'absolute', right: 'var(--memox-gutter)', bottom: 'calc(var(--memox-bottom-nav-height) + var(--memox-space-4))', zIndex: 11 }}>
          {fab}
        </div>
      ) : null}
      {bottomNav}
    </div>
  );
}
