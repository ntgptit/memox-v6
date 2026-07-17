/* MxMenu — the ONE action menu. Base class: menu.
   A vertical list of MenuItems (a raised popover surface, or embedded inside an MxSheet):
   each item is a labelled action with an optional leading icon and selected / destructive /
   disabled states. Items past the cap scroll inside the menu. Content is passed as data.

   This is the frozen replacement for the ad-hoc feature MenuItem — including the item
   `disabled` state — so the frozen family no longer has that gap (closes KIT-29-03 here).

   Runtime-authored (IIFE + global React) so the kit gallery can load it via
   <script type="text/babel-src"> without a bundle rebuild; ESM-exported too. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});

  function MxMenu(props) {
    const { items = [], onSelect, node, className = '', ariaLabel } = props;
    const cls = ['menu', className].filter(Boolean).join(' ');
    return (
      <div className={cls} data-mx-node={node} role="menu" aria-label={ariaLabel}>
        {items.map((it) => {
          const id = it.id;
          const itemCls = ['menu__item'];
          if (it.selected) itemCls.push('menu__item--selected');
          if (it.destructive) itemCls.push('menu__item--destructive');
          if (it.disabled) itemCls.push('menu__item--disabled');
          const icon = it.selected && !it.icon ? 'check' : it.icon;
          return (
            <button
              key={id}
              type="button"
              role="menuitem"
              className={itemCls.join(' ')}
              disabled={!!it.disabled}
              aria-disabled={it.disabled || undefined}
              aria-current={it.selected || undefined}
              data-mx-node={node ? `${node}/${id}` : undefined}
              onClick={() => { if (!it.disabled && onSelect) onSelect(id); }}
            >
              {icon ? <span className="material-symbols-rounded" aria-hidden="true">{icon}</span> : null}
              <span className="menu__item-label">{it.label}</span>
            </button>
          );
        })}
      </div>
    );
  }

  NS.MxMenu = MxMenu;
})();

export const MxMenu = (window.MemoXDesignSystem_2ffa54 || {}).MxMenu;
