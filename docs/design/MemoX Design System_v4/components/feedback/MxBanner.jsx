/* MxBanner — the ONE inline tone banner. Base class: banner.
   A non-blocking, in-flow message tinted by tone (info / success / warning / error): a
   leading tone icon, a title + optional body, and an optional trailing action. It sits in
   the content column, never over it — for blocking decisions use MxDialog.

   Tone drives the live-region role: info/success announce politely (role="status"),
   warning/error announce assertively (role="alert"). Colour comes only from tone tokens.

   Runtime-authored (IIFE + global React) so the kit gallery can load it via
   <script type="text/babel-src"> without a bundle rebuild; ESM-exported too. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});

  const TONE_ICON = { info: 'info', success: 'check_circle', warning: 'warning', error: 'error' };

  function MxBanner(props) {
    const { tone = 'info', title, children, icon, action, node, className = '' } = props;
    const cls = ['banner'];
    if (tone && tone !== 'info') cls.push('banner--' + tone);
    if (className) cls.push(className);
    // warning/error are assertive; info/success are polite.
    const role = tone === 'warning' || tone === 'error' ? 'alert' : 'status';
    const glyph = icon || TONE_ICON[tone];
    return (
      <div className={cls.join(' ')} data-mx-node={node} role={role}>
        {glyph ? <span className="material-symbols-rounded banner__icon" aria-hidden="true">{glyph}</span> : null}
        <div className="banner__content">
          {title ? <div className="banner__title">{title}</div> : null}
          {children ? <div className="banner__body">{children}</div> : null}
        </div>
        {action ? <div className="banner__action">{action}</div> : null}
      </div>
    );
  }

  NS.MxBanner = MxBanner;
})();

export const MxBanner = (window.MemoXDesignSystem_2ffa54 || {}).MxBanner;
