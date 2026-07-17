# Scope statement — MemoX Design System

> Closes audit items **KIT-01-02** (no Current/Future/Deprecated status field),
> **KIT-01-06** (no Supported/Not-supported/Planned scope matrix), **KIT-32-06**
> (foldable/split-view/hinge support statement), **KIT-33-01…33-05** (platform-profile /
> platform-parity scope), **KIT-36-06** (portrait-only statement), and the scope portions
> of **KIT-13-05** / **KIT-37** (RTL / i18n scope).

This document states, explicitly, what the kit **supports**, what it **does not
support**, and what is **planned**. Anything not listed as supported is out of scope and
must not be assumed to work. This replaces the previously silent phone-portrait
assumption.

## Domain model

The kit models **one `Deck` object**, distinguished by `parentId`:

- `parentId: null` → a **root deck** (listed in the Library).
- `parentId: <deck id>` → a **nested deck** (shown in the UI as a deck inside another deck).

There is **no separate "Subdeck" model** — a "subdeck" is only a Deck one level down. A Deck
holds nested decks (a `children` count) and/or cards. Hierarchy: **Library › Deck (→ nested Deck…)
› Card** — no Folder / Collection / Category / Workspace / Notebook layer.

Because a nested deck IS a Deck, the kit models **one deck-list screen** — `library` — for every
level: it renders the root (`parentId: null`, bottom-nav tab) and delegates its `nested-*` states
(a deck's child decks: pushed chrome, back + breadcrumb) to the same `SubdeckList` render module.
The standalone `subdeck-list` screen entry is retired (folded into `library`).

User-facing copy and internal component names use "Deck" / "nested deck" (`DeckCard`,
`DeckRowCard`, `CreateDeckSheet`). Per the AGENTS.md golden rule the group `SubdeckList`, its
render module, and the `subdeck-*` / `subdeck-list/*` `data-mx-node` ids stay **stable** (frozen
app-mapping contract — the `library` nested delegation renders those exact ids) even though the
display reads "Deck".

## Supported (in scope, verified)

| Dimension | Supported value | Evidence |
| --- | --- | --- |
| Target platform | **React Native** app; CSS/HTML kit is the design-reference/prototyping layer | `readme.md`, `SKILL.md` |
| Form factor | **Phone, portrait** | `ui_kits/memox-app/` gallery |
| Reference frame | **390 × 780** portrait; parity shot frame 390×780 | `tool/parity/verify-app-parity.mjs`, kit `shots/` |
| Themes | **Light** (`:root`) and **dark** (`[data-theme='dark']`) | `tokens/colors.css`; 168 light + 168 dark shots |
| Visual language | **One** visual language across iOS + Android — no per-platform adaptation | this document (§Platform) |
| Typography | Plus Jakarta Sans variable (200–800), identical on both platforms | `tokens/typography.css` |
| Icons | Material Symbols Rounded (CDN), identical on both platforms | `readme.md` iconography |
| Touch targets | ≥ 44×44 (baseline `--memox-touch-min: 48px`), identical on both platforms | `tokens/spacing.css` |
| Language / direction | **English, LTR** placeholder content | `_features/**` |

## Not supported (out of scope, not planned)

| Dimension | Status | Note |
| --- | --- | --- |
| **Tablet / large-screen** layouts | Not supported | No large-screen breakpoints, adaptive grids, or multi-pane layouts. |
| **Landscape** orientation | Not supported | Kit is portrait-only; landscape is not designed or shot. |
| **Foldable / split-view / hinge** | Not supported | No foldable/dual-screen/hinge-aware layouts or postures. |
| **Platform-specific (iOS vs. Android) adaptation** | Not supported | Single visual language; MemoX does **not** adapt controls to Cupertino/Material per platform. See platform decisions below. |
| **RTL** (right-to-left) | Not supported | No logical properties/mirroring; directional icons (`chevron_right`, `arrow_back`) do not mirror. Product is LTR-only. |
| **i18n / string externalization** | Not supported | Copy is English-only, hardcoded in JSX; no locale-format layer for number/date/plural/unit. |
| **Swipe / drag gesture motion** | Not supported (accepted) | No follow-finger / cancel-return gesture motion. Every action is button-driven. See §Accepted scope decisions (KIT-38-04). |
| **Push / pop / modal transition clips** | Not supported (accepted) | Duration/easing tokens exist, but no recorded transition clips are produced. See §Accepted scope decisions (KIT-38-02). |
| **Platform flow recordings** (back-gesture / modal / nav) | Not supported (accepted) | One presentation documented; no per-platform flow recordings. See §Accepted scope decisions (KIT-33-02). |

## Planned (future, not yet in the kit)

| Item | Status | Tracked by |
| --- | --- | --- |
| Brand logo / app-icon asset + clear-space/min-size/dark-bg specs | Planned | `governance/asset-export-spec.md`, `exception-register.md` (EXC-02) |
| Real product content replacing placeholders | Planned | `exception-register.md` (EXC-03) |
| High-contrast profile (`[data-hc='true']`) rollout across screens | Planned | additive; token profile defined |
| Localization expansion corpus + CJK/Vietnamese font-stack declaration | Planned | audit KIT-37 |
| Dashboard slice completion | Planned | WBS 5.3, `REMAINING-DIVERGENCES.md` |

## Platform decisions (single visual language)

MemoX ships **one** visual language on both iOS and Android — it does not swap to
Cupertino or platform-native controls. The relevant component/interaction choices:

| Concern | Decision | Rationale |
| --- | --- | --- |
| Switch / toggle | Custom `MxSwitch` (thumb grows as it travels) on both platforms | One brand feel; no iOS/Android divergence |
| Segmented control | Custom `MxSegmentedControl` | Consistent tinted pill across platforms |
| Selection / action sheets | Custom `MxCard`-based sheets (`DeckActionsSheet`, `SelectSheet`, `ValuePickerSheet`, …) | Brand-consistent bottom sheets, not OS action sheets |
| Time picker | Custom `TimePickerSheet` (reminder) | Matches the kit's sheet system rather than the OS wheel/clock picker; consistent chrome and theming |
| Back gesture / modal / navigation | One presentation, not platform-specific flow recordings | Single visual language; platform gesture behavior is delegated to RN navigation at runtime |

There is intentionally **no** platform-parity matrix that adapts these controls per OS —
the parity is "identical on both," which is the design decision, not a gap.

## Accepted scope decisions (gesture motion & flow recordings)

MemoX v4 is a **button-driven, static visual reference kit**: it defines tokens,
components, and screen *states* rendered as still frames at 390×780. The following are
**ACCEPTED as out of scope** — a deliberate boundary of that kit, not an unaddressed gap.

| ID | Decision (ACCEPTED, out of scope) | Rationale | Revisit trigger |
| --- | --- | --- | --- |
| **KIT-38-04** | **Swipe / drag gesture motion** (follow-finger tracking, cancel-return, rubber-banding) is not designed or demonstrated. | The kit is button-driven by design — every action has an explicit `Mx*` control (buttons, sheets, toggles). Continuous gesture *motion* is a runtime interaction concern delegated to React Native gesture/navigation libraries, not a static design-reference artifact. Demonstrating follow-finger physics needs a live runtime, not the still-frame kit. | Introduce a product feature whose primary interaction **is** a gesture (e.g. swipe-to-delete as the only affordance), or stand up an interaction-prototype layer. Then spec the gesture motion + cancel/commit thresholds. |
| **KIT-38-02** | **Push / pop / modal / pane transition clips** are not produced. | The motion **tokens** (`--memox-duration-*`, easing) exist and govern transitions at runtime, and reduced-motion is handled (`--memox-duration-none`). Recording animated transition *clips* requires a running app and a video pipeline outside the still-frame + pixel-parity contract; capturing them would not feed the 390×780 parity gate. | Add a motion-spec / video-capture pipeline, or a requirement to certify specific transition curves. Then record push/pop/modal clips against the duration tokens. |
| **KIT-33-02** | **Platform flow recordings** (per-OS back-gesture, modal presentation, navigation flow) are not produced. | MemoX ships **one** visual language on both platforms (see §Platform decisions). Platform gesture/navigation behaviour is delegated to RN navigation at runtime; recording per-OS flows would document runtime navigation, not the kit's single-presentation design. | Adopt a per-platform navigation divergence (contradicting the single-visual-language decision), or add a runtime-QA layer that certifies platform flows. Then record them. |

These decisions are **reviewed each release** (see `governance/versioning.md`); if a
revisit trigger fires, the item moves from ACCEPTED to Planned and is scoped in.

## Artifact status taxonomy (Current / Future / Deprecated)

The kit is a single `v4` release, so **every shipped artifact is implicitly `Current`**
unless marked otherwise. This taxonomy makes the status explicit going forward:

| Status | Meaning | Where recorded |
| --- | --- | --- |
| **Current** | Shipped in `v4`, supported, safe to use | default for all tokens/`Mx*`/composites in `_ds_manifest.json` |
| **Future** | Planned, defined but not rolled out | this file §Planned; `CHANGELOG.md` [Unreleased] |
| **Deprecated** | Replaced; new usage blocked; awaiting usage=0 removal | `governance/deprecation-policy.md` register |

Currently deprecated artifacts: legacy Tokyo color values (migrated/retired) and
`--memox-appbar-lg-height` (kept for compatibility). See the deprecation register.
