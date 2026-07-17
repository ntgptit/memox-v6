// Loads this design system into the template. In a consuming project, point
// base at the bound DS folder relative to this file (e.g. '_ds/<folder>' at
// the project root, '../_ds/<folder>' one level down) — one line to edit.
//
// This template is a STATIC scaffold built from the frozen Mx* CSS base classes
// (.app, .cappbar, .card, .btn…) with data-mx-node ids — it needs only the tokens +
// component stylesheet, not any component JavaScript. (There is no compiled bundle:
// the design system renders from source; see components/_ds_runtime.js.)
(() => {
  const base = '../..';
  for (const p of ["styles.css"]) {
    const l = document.createElement('link');
    l.rel = 'stylesheet'; l.href = base + '/' + p;
    document.head.appendChild(l);
  }
})();
