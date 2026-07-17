import React from 'react';

/* MxSectionHeader — list/section label row. Base class: section-head */
export function MxSectionHeader({ title, caption, action, onAction, actionLabel, node }) {
  // The action is a role="button" span, so it must also fire on Enter/Space (native buttons do
  // this for free; ARIA buttons don't). Without this it is mouse-only — a keyboard/AT trap.
  const onKey = onAction ? (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onAction(e); } } : undefined;
  return (
    <div className="section-head" data-mx-node={node}>
      <div className="section-head__text">
        <div className="section-head__title" role="heading" aria-level={2}>{title}</div>
        {caption ? <div className="section-head__caption">{caption}</div> : null}
      </div>
      {action ? (
        <span className="section-head__action" onClick={onAction} onKeyDown={onKey}
          role="button" tabIndex={0} aria-label={actionLabel || undefined}>{action}</span>
      ) : null}
    </div>
  );
}
