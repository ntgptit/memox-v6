# Changelog — MemoX Design System

> Closes audit items **KIT-02-06** (no changelog/version-history proving the v4 snapshot
> is frozen) and **KIT-48-05** (no version metadata / changelog for release).

All notable changes to this kit are recorded here. This file is the source of truth for
version history and consumer notification (see `governance/versioning.md`). Impact
classes: **[additive]** new names, nothing renamed/removed · **[value]** value-only,
names/ids stable · **[breaking]** an existing name/id/class removed or renamed · **[docs]**.

The format follows Keep-a-Changelog conventions adapted to the kit's frozen-identifier
contract. Dates are ISO. The kit's major version is encoded in the folder name
(`MemoX Design System_v4`).

---

## [Unreleased] — targeting v4.1 kit freeze

Audit-remediation batch (below) closing governance / release / scope / deprecation gaps from
`../mobile-design-kit-audit-v5/issue-register.md` — **additive and documentation only** — plus a
**unified Deck-model** workstream (kept additive to the frozen contract: no token / `Mx*` / base
class / `data-mx-node` id was renamed or removed). Existing 390×780 light+dark shots are
pixel-unchanged except the newly added `library--nested-*` set.

### Added — governance & release docs [docs]
- `governance/OWNERS.md` — ownership index mapping foundation/component/pattern/theme to
  owner (Design System team) + reviewer role (KIT-46-01).
- `governance/CONTRIBUTING.md` — contribution template: use-cases, duplicate-check,
  required states, a11y, docs (KIT-46-02).
- `governance/acceptance-criteria.md` — token vs. component vs. pattern acceptance matrix
  (KIT-46-03).
- `governance/versioning.md` — version-bump/approval/migration/cadence/notification
  process (KIT-46-04, KIT-46-05).
- `governance/deprecation-policy.md` + structured deprecation table and the lint-blocks-
  new-usage rule (KIT-47-02…47-06).
- `governance/duplicate-scan.md` — duplicate/near-duplicate scan process (KIT-47-01).
- `governance/exception-register.md` — exceptions with owner/target/expiry (KIT-40-06,
  KIT-46-06).
- `governance/asset-export-spec.md` — asset export spec + tracked logo/app-icon gap
  (KIT-14-05, KIT-45-05).
- `governance/coverage-report.md` — aggregated shots/specs/contrast coverage (KIT-48-04).
- `governance/release-signoff.md` — sign-off record template, status BLOCKED (KIT-42-06,
  KIT-48-01, KIT-48-02, KIT-48-06).
- `governance/component-promotion.md` — promotion evaluation of recurring `_shared`
  composites (KIT-15-06).
- `SCOPE.md` — supported/not-supported/planned matrix + Current/Future/Deprecated status
  taxonomy (KIT-01-02, KIT-01-06, KIT-32-06, KIT-33-*, KIT-36-06).
- `CHANGELOG.md` — this file (KIT-02-06, KIT-48-05).

### Added — remediation round 2: documentation & assets (2026-07-16) [docs] [additive]
- `governance/theme-onboarding.md` — new-theme onboarding checklist (define values → contrast
  gate → capture shots → parity check → sign off) + a worked completed run for the existing
  dark theme (KIT-07-05).
- `guidelines/system-ui.md` — status-bar icon-mode and Android system nav-bar appearance spec,
  mapped by theme + surface luminance (KIT-34-05).
- `guidelines/input-autofill.md` — autofill / password-manager spec: `autoComplete` +
  `textContentType` (+ keyboard/capitalization) mapping per field type (KIT-35-05).
- `guidelines/permissions-capabilities.md` — device-permission capability-state matrix
  (camera / microphone / notification / biometric × granted / denied / restricted → UI +
  recovery) (KIT-36-05).
- `guidelines/keyboard-focus-order.md` §5 — concrete tab-by-tab "add a card" keyboard
  walkthrough with no-trap + completion proofs, as an executable checklist (KIT-42-02).
- `assets/memox-wordmark.svg` + `assets/memox-wordmark-dark.svg` — MemoX's own typographic
  wordmark (Plus Jakarta Sans Extrabold; `#4b3a8c` light, `#f6f5fc` on dark), plus a full
  clear-space / min-size / light-dark usage spec in `governance/asset-export-spec.md`. Remains
  a typographic wordmark pending a bespoke brand icon (KIT-14-05); `exception-register.md`
  EXC-02 narrowed to the icon/app-icon gap.
- `SCOPE.md` §Accepted scope decisions — swipe/drag gesture motion (KIT-38-04), push/pop/modal
  transition clips (KIT-38-02), and platform flow recordings (KIT-33-02) recorded as ACCEPTED
  out-of-scope for the button-driven static reference kit, each with rationale + revisit trigger.

### Changed — unified Deck model (2026-07-17) [additive] [docs]
One `Deck` model, distinguished by `parentId` (`null` = root deck, `<deck id>` = nested deck) —
there is no separate "Subdeck" object. A "subdeck" is only a Deck one level down.
- Fixtures carry `id` + `parentId` + `children`; user-facing copy is "Deck" / "nested deck"
  (section labels DECKS / NESTED DECKS). The list adapter is `_features/library/components/
  DeckRowCard.jsx` and the create sheet `CreateDeckSheet.jsx` (renamed from the `Subdeck*`
  variants — these are `_features`-local file names, not `Mx*`/manifest/`data-mx-node`
  identifiers). `SCOPE.md` §Domain model documents the contract.
- **Library is now the ONE deck-list screen for every level.** The `library` screen renders the
  root (`parentId: null`, bottom-nav tab) and **delegates its 15 new `nested-*` states** to the
  `SubdeckList` render module (a deck's child decks). The nested mode is now **chrome-identical to
  the root** — same `FilterRow` controls (All decks / Filters / A–Z) and the same bottom nav
  (passed down from `library`, Library tab active) — differing only by the back button +
  breadcrumb it adds for navigating up. `FilterRow` gained an additive `prefix` prop so its node
  ids scope to the host screen (`library/*` at root, `subdeck-list/*` nested). Added
  `library--nested-*` canonical shots (15 states × light+dark). The `subdeck-list`
  **registry/spec screen entry was folded into `library`** (its generated `specs/subdeck-list.md`
  removed).
- **Frozen contract preserved (golden rule):** the group `SubdeckList`, its render module, and
  every `subdeck-*` / `subdeck-list/*` `data-mx-node` id are **unchanged** — the delegation
  renders those exact ids, so no app-mapping identifier moved. The frozen `subdeck-list--*` kit
  shots are **retained** as the parity reference for the app's still-present subdeck-list screen.
- **App-alignment follow-ups (tracked, not blocking):** align the app's create-deck copy to the
  unified model (`deck-content-choice` allowlisted at ~3.3–3.5%), and collapse the app's
  `library` + `subdeck-list` into one screen, then re-baseline against `library--nested-*` and
  retire the `subdeck-list--*` shots. See `tool/parity/REMAINING-DIVERGENCES.md`.

### Changed — flat app bar, no elevate-on-scroll (2026-07-17) [value]
`MxContextualAppBar` no longer changes colour or gains a surface / divider / shadow when the body
scrolls. root/nested/search now use **one flat background = the screen colour** (`--memox-bg`) at
every scroll position — `top` and `scrolled` render identically, so the safe area, bar and body
read as a single unbroken block in both light and dark. Only `selection` / `modal` keep a surface
+ hairline (they are transient MODE bars, not scroll states).
- `components.css`: `.cappbar` background = `--memox-bg`; `.cappbar--top`/`--scrolled` flat with a
  transparent bottom border; a new `.cappbar--selection`/`--modal` rule carries the mode surface +
  divider; the notification-badge ring keys off `.cappbar--root` (always the flat bg).
- The `collapsed` prop is retained only to pin gallery states — it has no visual effect now.
- Value-only: no token / `Mx*` / class / `data-mx-node` id changed. Only `app-bar--root-scrolled`
  re-baselined (it now matches `root-top`); all other shots are pixel-unchanged.

### Notes
- The audit batch is additive/doc/asset changes; the Deck-model workstream is additive to the
  frozen contract (see above). No consumer migration required; no token/`Mx*`/class/
  `data-mx-node` identifier renamed or removed; existing 390×780 light+dark shots unchanged
  aside from the added `library--nested-*` set (the new specs govern RN-runtime OS chrome /
  states that no existing fixture triggers).
- Open P0/P1 audit items (e.g. RTL/i18n KIT-37, responsive KIT-32, some a11y) remain
  tracked; release stays **BLOCKED** per `governance/release-signoff.md`.

---

## [v4] — deep-violet baseline (frozen)

The from-scratch v4 visual system for MemoX (React Native), frozen under
`MemoX Design System_v4/`. This is the baseline snapshot; the entries below describe the
state captured at freeze, reconstructed from the kit sources (`readme.md`,
`_ds_manifest.json`, tokens, components).

### Foundation
- Deep-violet palette as the single color source of truth in `tokens/colors.css` —
  primary `#4b3a8c`, accent `#7355d6` (light) / `#a88fff` (dark), full light (`:root`)
  and dark (`[data-theme='dark']`) role sets, semantic success/warning/error/info.
- Token layers: `colors`, `typography` (+ `@font-face`), `spacing`, `component`,
  `opacity`, `radius`, `stroke`, `size`, `icon-size`, `elevation`, `motion`.
- Typeface: Plus Jakarta Sans variable (weight `200 800`),
  `fonts/PlusJakartaSans[wght].ttf`.
- Icons: Material Symbols Rounded (Google Fonts CDN), weight 400 / FILL 0.

### Components
- Frozen `Mx*` family: core (`MxButton`, `MxTextField`, `MxChip`, `MxBadge`, `MxSwitch`,
  `MxSegmentedControl`, `MxAvatar`, `MxLink`), surfaces (`MxScaffold`,
  `MxContextualAppBar`, `MxCard`, `MxSectionHeader`, `MxIconTile`, `MxList`), navigation
  (`MxBottomNav`, `MxFab`, `MxSearchDock`, `MxIconButton`). Each has a stable PascalCase
  name + stable base class; variants are modifiers.

### Screens
- App UI kit: **26 screens** under `ui_kits/memox-app/_features/`, assembled only from
  `Mx*` + kit-helpers, each state carrying a `data-mx-node` id — rendered in light + dark
  (**336** shots = 168 light + 168 dark) with **26** DOM specs under `specs/`.
- Kit ↔ app parity gate at **< 3%** per state × theme (`tool/parity/`), with **165**
  app-golden baseline shots.

### Migrations at freeze [value]
- **Legacy Tokyo-palette colors → deep violet.** An earlier revision sampled the Tokyo
  admin dashboard for its *color values only*; those values were fully migrated to deep
  violet before freeze (`readme.md`). No token names, component names/classes, or layout
  ever came from Tokyo — only the now-replaced color values. Do not reintroduce them.
  Tracked in `governance/deprecation-policy.md`.

### Known caveats at freeze
- No brand logo / app-icon asset — the wordmark is Plus Jakarta Sans Extrabold type
  (tracked in `governance/asset-export-spec.md` and `exception-register.md`).
- Screens use realistic placeholder copy/data; no real content/navigation/validation.
- Scope is phone portrait 390×780 (see `SCOPE.md`).
