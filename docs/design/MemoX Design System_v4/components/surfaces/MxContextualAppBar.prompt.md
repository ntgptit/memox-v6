MxContextualAppBar — the ONE shared top app bar for every screen. Never build a per-screen header; pass content by semantic slot and pick a `variant`.

```jsx
// Root destination (Home/Today): date context at top, collapses to "Today" on scroll.
<MxContextualAppBar variant="root-contextual" context="Saturday · 27 Jun" title="Today"
  notification={{ dot: true }} avatar={<MxAvatar name="Linh Tran" size="sm" />} node="dashboard/appbar" />

// Root standard (Library): fixed title + one action + avatar.
<MxContextualAppBar variant="root-standard" title="Library"
  actions={<MxIconButton icon="search" size="sm" ariaLabel="Search" />} avatar={AV} />

// Nested detail: back + title + up to 2 actions (3rd -> overflow).
<MxContextualAppBar variant="nested" title="Korean Basics"
  actions={<><MxIconButton icon="search" size="sm" ariaLabel="Search in deck" /><MxIconButton icon="more_vert" size="sm" ariaLabel="More" /></>} />

// Search / Selection / Focused.
<MxContextualAppBar variant="search" search={{ placeholder: 'Search decks and cards' }} actions={<MxIconButton icon="close" size="sm" ariaLabel="Clear" />} />
<MxContextualAppBar variant="selection" count={3} actions={<><MxIconButton icon="select_all" size="sm" ariaLabel="Select all" /><MxIconButton icon="more_vert" size="sm" ariaLabel="More" /></>} />
<MxContextualAppBar variant="focused" title="Card 7 of 20" leading={<MxIconButton icon="close" size="sm" ariaLabel="Exit" />} />
```

Rules:
- Max **2** direct right actions (avatar counts as one). No decorative icons; no action that already exists as a FAB or bottom-nav destination.
- `root-contextual`: show the context label ONLY at top and the destination title ONLY when scrolled — never both. Don't duplicate the context (e.g. the date) in the body.
- Notification: omit the badge at 0; use a dot for "has new", a numeric badge (99+ cap) only when the number is useful.
- **Flat at every scroll position:** root/nested/search use one background = the screen colour and gain NO surface, divider, or shadow when the body scrolls (the safe area, bar and body read as one block). selection/modal carry a surface + hairline as transient MODE bars. Same anatomy/size in light and dark — only tokens change.
- Do NOT move a screen's greeting/heading into the bar; the bar holds context + title + actions only.

---

**When not to use** — Never build a per-screen header — always use this. Not for in-body section headings (use `MxSectionHeader`).

**States** — variants `root`/`nested`/`search`/`selection`/`modal` (`root-contextual`/`root-standard`/`focused` are `root`/`modal` compositions); root/nested/search are flat at every scroll position (no surface/divider on scroll — top == scrolled); selection/modal carry a surface + hairline as mode bars; notification `dot`/`count`; selection `count` announced via `role="status"`. RN: header region, honours top safe-area. Full a11y/reading-order contract lives in `MxContextualAppBar.d.ts`.

**Content limits / i18n** — `title` is single-line and truncates; max 2 right actions (avatar counts as one); `context` label stays short. Title/context expand across locales — truncate the title, never wrap or grow the bar. RTL: back/leading and actions mirror to logical start/end.

**Do / Don't** — Do pass content by semantic slot and pick a `variant`. Don't exceed 2 actions; don't duplicate a FAB or bottom-nav destination as a bar action.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
