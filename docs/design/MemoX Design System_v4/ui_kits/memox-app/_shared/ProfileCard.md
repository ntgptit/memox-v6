# ProfileCard — shared composite

An avatar + name + email identity row inside an `MxCard`, with an optional
trailing badge. Owns the card that `settings` (settings/profile) and
`account-sync` (account/profile) previously duplicated verbatim.

```jsx
// settings: plain identity card
<window.ProfileCard node="settings/profile" />

// account-sync: adds the ALPHA tag
<window.ProfileCard node="account/profile"
  badge={<window.MemoXDesignSystem_2ffa54.MxBadge tone="warning" soft>ALPHA</window.MemoXDesignSystem_2ffa54.MxBadge>} />
```

## Props
- `node` — `data-mx-node` id (per-caller: `settings/profile` · `account/profile`).
- `badge` — optional trailing badge node (account-sync's ALPHA; settings omits it).

## Rules
- The name/email are a static scaffold **fixture** (identical in both callers) —
  they live here once; do not re-parameterize them in the kit prototype.
- `node` + `badge` are the ONLY per-caller inputs; anything more per-screen belongs
  back in that screen, not here.

## Flutter target
- Component → an `MxProfileCard` widget (`presentation/shared/composites/`).
- v1 divergence (documented): the Flutter card shows the app's **local** identity
  — the MemoX wordmark + on-device subtitle (D-027, no account/sync in v1) — not a
  signed-in name/email. Copy from ARB.
- `badge` → an optional trailing `Widget`; it is **account-sync only** (deferred,
  WBS S.22), so the v1 Flutter card omits it (recorded as a `deferred-screen`
  props-parity exception). `node` → `ValueKey`.
