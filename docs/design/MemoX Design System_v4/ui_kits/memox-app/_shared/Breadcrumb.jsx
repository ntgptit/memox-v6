/* MemoX shared widget: Breadcrumb — the nested-deck path affordance for a multi-level tree
   (Library › Korean › TOPIK I › Grammar). Ancestor crumbs are tappable (navigate up); the
   current level is bold, non-interactive. A path deeper than `maxVisible` collapses its
   middle into a tappable "…" crumb so the root and the last two levels stay visible; the
   row also scrolls horizontally as a fallback. Base class: `breadcrumb`.

   Props:
     items      : [{ label, node, current? }]  — ordered root → current; mark the last
                  `current: true` to render it as the bold, non-link page crumb.
     maxVisible : collapse threshold (default 4).
     node       : data-mx-node for the <nav>.

   Runtime-authored (IIFE + global React) like the other kit widgets; ESM-exported too. */
(function () {
  function Sep() {
    return <span className="breadcrumb__sep material-symbols-rounded" aria-hidden="true">chevron_right</span>;
  }

  function Crumb({ item }) {
    if (item.current) {
      return <span className="breadcrumb__current" aria-current="page">{item.label}</span>;
    }
    return (
      <button type="button" className="breadcrumb__crumb" data-mx-node={item.node}
        aria-label={item.ellipsis ? 'Show hidden levels' : item.label}>{item.label}</button>
    );
  }

  function Breadcrumb({ items = [], maxVisible = 4, node }) {
    let shown = items;
    if (items.length > maxVisible) {
      // root · … · parent · current — keep the two innermost levels + the root
      shown = [items[0], { label: '…', node: (node || 'breadcrumb') + '/expand', ellipsis: true }, items[items.length - 2], items[items.length - 1]];
    }
    return (
      <nav className="breadcrumb" data-mx-node={node} aria-label="Breadcrumb">
        {shown.map((it, i) => (
          <React.Fragment key={i}>
            {i > 0 ? <Sep /> : null}
            <Crumb item={it} />
          </React.Fragment>
        ))}
      </nav>
    );
  }

  window.Breadcrumb = Breadcrumb;
})();

export const Breadcrumb = window.Breadcrumb;
