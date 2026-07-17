/* MemoX component-card runtime — loads the base Mx* primitives from SOURCE (no compiled
   bundle). Mirrors the app gallery's in-browser loader: fetch each <script type="text/babel-src">
   file, strip ESM import/export, transpile with the page's global Babel, register every Mx*
   on the frozen namespace INCREMENTALLY (screens/demos read them off NS at load time), then run
   the single <script type="text/babel-demo"> once every primitive is registered.

   Requires React, ReactDOM and @babel/standalone to be loaded first (the card <head>). This
   file replaces the old compiled-bundle include so the reference cards render the current source
   with zero compiled-artifact drift — the same reason the gallery dropped the bundle. */
(function () {
  function strip(code) {
    return code
      .replace(/^[ \t]*import[ \t].*$/gm, '')
      .replace(/^([ \t]*)export[ \t]+/gm, '$1');
  }
  function run(code, label) {
    var out = Babel.transform(code, { presets: ['react'], filename: label }).code;
    var s = document.createElement('script');
    s.textContent = out + '\n//# sourceURL=' + label;
    document.head.appendChild(s);
  }
  var NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});
  function registerMx() {
    Object.keys(window).forEach(function (k) {
      if (/^Mx[A-Z]/.test(k) && typeof window[k] === 'function' && !NS[k]) NS[k] = window[k];
    });
  }
  async function boot() {
    var srcs = Array.prototype.slice.call(
      document.querySelectorAll('script[type="text/babel-src"]')
    ).map(function (t) { return t.getAttribute('src'); });
    var texts = await Promise.all(srcs.map(function (src) {
      return fetch(src).then(function (r) { return r.text(); })
        .catch(function (e) { console.error('card fetch failed:', src, e); return ''; });
    }));
    for (var i = 0; i < srcs.length; i++) {
      if (!texts[i]) continue;
      try { run(strip(texts[i]), srcs[i]); }
      catch (e) { console.error('card run failed:', srcs[i], e); }
      registerMx();
    }
    // Wrap the demo in an IIFE so its top-level `const { MxButton } = NS` destructuring is
    // function-scoped and does not clash with the global `function MxButton` a base-primitive
    // source declares (the app gallery's screen modules are already IIFE-authored).
    var demo = document.querySelector('script[type="text/babel-demo"]');
    if (demo) run('(function () {\n' + strip(demo.textContent) + '\n})();', 'demo.jsx');
  }
  boot();
})();
