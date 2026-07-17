/* MxContextualAppBar — the ONE app bar for every screen. Base class: cappbar.
   Minimal, FLAT: a single 56px bar, start-aligned title, one flat background = the screen
   colour. It does NOT change colour or gain a surface / divider / shadow as the body scrolls —
   the safe area, the bar and the body read as one unbroken block, at any scroll position, in
   both light and dark. Content is passed by semantic slot, never screen-specific markup.

   Variants:
     root      — tab destinations: title + trailing actions (search / notification / avatar).
     nested    — pushed detail screens: back + title + optional actions.
     search    — back + a filled search field.
     selection — close + "N selected" + selection actions (mode bar: surface + hairline).
     modal     — full-screen form: close + centered title + a primary action (mode bar).
   root / nested / search are seamless (flat, no scroll change); selection / modal are transient
   MODE bars that carry a surface + hairline to separate the mode chrome from content.
   The `collapsed`/scroll state no longer changes root/nested/search visually — top == scrolled;
   the prop is retained only to pin gallery states.

   Runtime-authored (IIFE + global React) so the kit gallery loads it via babel-src without a
   bundle rebuild; ESM-exported for the design-system compiler. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});
  const { MxIconButton } = NS;
  const R = window.React;

  function Bell({ count, dot }) {
    const badge = count > 0 || dot;
    const label = count > 0 ? `Notifications, ${count > 99 ? '99+' : count} unread` : 'Notifications';
    return (
      <span className="cappbar__notif" data-mx-node="shell/notifications">
        <MxIconButton icon="notifications" size="sm" node={null} ariaLabel={label} />
        {badge ? (
          <span className={'cappbar__badge' + (count > 0 ? '' : ' cappbar__badge--dot')} aria-hidden="true">
            {count > 0 ? (count > 99 ? '99+' : count) : ''}
          </span>
        ) : null}
      </span>
    );
  }

  function MxContextualAppBar(props) {
    const {
      variant = 'root', collapsed: collapsedProp, title, count,
      search, leading, actions, notification, avatar, node, className = '',
    } = props;

    // root / nested / search blend at the top and gain a surface + divider on scroll.
    const elevates = variant === 'root' || variant === 'nested' || variant === 'search';
    const [auto, setAuto] = R.useState(false);
    const ref = R.useRef(null);
    R.useEffect(() => {
      if (collapsedProp !== undefined || !elevates || !ref.current) return;
      const app = ref.current.closest('.app');
      const body = app && app.querySelector('.app__body');
      if (!body) return;
      const onScroll = () => setAuto(body.scrollTop > 8);
      onScroll();
      body.addEventListener('scroll', onScroll, { passive: true });
      return () => body.removeEventListener('scroll', onScroll);
    }, [collapsedProp, elevates]);
    const scrolled = collapsedProp !== undefined ? collapsedProp : (elevates ? auto : true);
    const cls = ['cappbar', 'cappbar--' + variant, scrolled ? 'cappbar--scrolled' : 'cappbar--top', className].filter(Boolean).join(' ');

    // Leading slot: explicit override, else a sensible default per variant.
    const lead = leading !== undefined ? leading
      : variant === 'nested' || variant === 'search' ? <MxIconButton icon="arrow_back" size="sm" node="shell/back" ariaLabel="Back" />
      : variant === 'modal' || variant === 'selection' ? <MxIconButton icon="close" size="sm" node="shell/close" ariaLabel="Close" />
      : null;

    // Center content by variant.
    let main;
    if (variant === 'search') {
      main = (
        <div className="cappbar__search" data-mx-node="shell/search">
          <span className="material-symbols-rounded cappbar__search-icon">search</span>
          <input className="cappbar__search-input" placeholder={(search && search.placeholder) || 'Search'} defaultValue={search && search.value} aria-label="Search" />
        </div>
      );
    } else if (variant === 'selection') {
      main = <div className="cappbar__title" role="status">{count} selected</div>;
    } else {
      // The bar title is the screen's top-level heading — expose it as a heading landmark
      // so screens have a reachable H1 for AT. (role/aria-level add no pixels.)
      main = <div className="cappbar__title" role="heading" aria-level={1}>{title}</div>;
    }

    // Right cluster: generic actions, then notification, then avatar.
    const right = (
      <div className="cappbar__actions">
        {actions}
        {notification ? <Bell count={notification.count} dot={notification.dot} /> : null}
        {avatar}
      </div>
    );

    return (
      <header ref={ref} className={cls} data-mx-node={node}>
        {lead ? <div className="cappbar__lead">{lead}</div> : null}
        <div className="cappbar__main">{main}</div>
        {right}
      </header>
    );
  }

  NS.MxContextualAppBar = MxContextualAppBar;
})();

export const MxContextualAppBar = (window.MemoXDesignSystem_2ffa54 || {}).MxContextualAppBar;
