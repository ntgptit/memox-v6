# MemoX — App UI Kit

A high-fidelity, click-through recreation of the MemoX mobile app (local-first flashcard / spaced-repetition study). Every screen is assembled **only** from the `Mx*` component family — no loose card/button/layout markup — and rendered through all of its states in **light + dark**.

## Open

`index.html` is the gallery. Each **row** is one screen; a **stepper** cycles its states; each state is framed in a phone-sized **device frame** with a **label**, shown in both themes.

## Screens & states

The full, authoritative list of screens and their states lives in
[`specs/INDEX.md`](specs/INDEX.md) (generated from the registry — do not restate
counts here, they drift). Each screen has a feature module under
[`_features/<screen>/`](./_features/) and per-state DOM specs + rendered PNGs
under [`specs/`](./specs/) and [`shots/`](./shots/).

`kit-helpers.jsx` holds kit-only composites built from primitives + tokens
(`ProgressBar`, `Skeleton`, `EmptyState`, `DeckRow`, `ListRow`, `Stat`, `Scrim`,
`Sheet`, `MenuItem`, `Dialog`, `Note`, `SectionLabel`, `Ring`, `ChoiceOption`)
and exports them to `window`.

## Identity contract

Every meaningful node carries a stable `data-mx-node="<screen>/<node>"` — e.g. `dashboard/due-summary`, `library/search-dock`, `study-session/progress`. These are semantic anchors: keep the id on the equivalent node through any redesign; new nodes get new ids; never reuse or delete an id. Shared primitives receive their `data-mx-node` from the call site (passed as the `node` prop).

## Load order (important)

Base `Mx*` primitives (`../../components/**/*.jsx`) → `kit-helpers.jsx` → screen modules → gallery — all loaded from **source** as `text/babel-src` and transpiled in-browser (no compiled bundle). The boot loader registers each primitive on `window.MemoXDesignSystem_2ffa54` incrementally as it loads, so screen modules resolve them at load time; screens export themselves to `window`.

## Note

This is a **recreation/scaffold** for prototyping, not production code — interactions are cosmetic (state stepping, switches/segments), and copy is realistic placeholder.
