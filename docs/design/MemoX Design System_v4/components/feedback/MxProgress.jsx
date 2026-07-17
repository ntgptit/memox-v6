/* MxProgress — the ONE progress indicator. Base class: progress.
   Determinate or indeterminate work, as a linear bar or an inline spinner:
     - bar + `value` (0–100)        → determinate track + fill.
     - bar with no `value`          → indeterminate sliding fill.
     - spinner (with/without value) → inline circular indicator (spinner is indeterminate).
   role="progressbar" with aria-valuenow/min/max when determinate. The looping motion
   honours prefers-reduced-motion (settles via --memox-duration-none). Colour from tokens.

   Runtime-authored (IIFE + global React) so the kit gallery can load it via
   <script type="text/babel-src"> without a bundle rebuild; ESM-exported too. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});

  function clamp(n) { return Math.max(0, Math.min(100, n)); }

  function MxProgress(props) {
    const { variant = 'bar', value, ariaLabel = 'Loading', node, className = '' } = props;
    const determinate = typeof value === 'number';
    const pct = determinate ? clamp(value) : undefined;

    const aria = {
      role: 'progressbar',
      'aria-label': ariaLabel,
      'aria-valuemin': determinate ? 0 : undefined,
      'aria-valuemax': determinate ? 100 : undefined,
      'aria-valuenow': determinate ? pct : undefined,
    };

    if (variant === 'spinner') {
      const cls = ['progress', 'progress--spinner', className].filter(Boolean).join(' ');
      // The spinner is always indeterminate motion; expose value to AT when known.
      return (
        <div className={cls} data-mx-node={node} {...aria}>
          <span className="progress__spinner" aria-hidden="true" />
        </div>
      );
    }

    const cls = ['progress', determinate ? '' : 'progress--indeterminate', className].filter(Boolean).join(' ');
    const fillStyle = determinate ? { width: pct + '%' } : undefined;
    return (
      <div className={cls} data-mx-node={node} {...aria}>
        <div className="progress__track">
          <div className="progress__fill" style={fillStyle} />
        </div>
      </div>
    );
  }

  NS.MxProgress = MxProgress;
})();

export const MxProgress = (window.MemoXDesignSystem_2ffa54 || {}).MxProgress;
