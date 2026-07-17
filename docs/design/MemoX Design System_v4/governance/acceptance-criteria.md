# Acceptance-criteria matrix — token vs. component vs. pattern

> Closes audit item **KIT-46-03** (no acceptance-criteria matrix distinguishing token /
> component / pattern).

Acceptance criteria differ by layer. A change is **Done** only when every criterion for
its layer is satisfied and cited (rule, fixture, or gate — never "looks good"). All
three layers inherit the frozen-identifier rule: additive-only names; values may change;
no raw visual values above the token layer.

Legend for the checks referenced below:
- **Lint** — `_adherence.oxlintrc.json` (`npm run lint`)
- **Kit** — `npm run verify:ui-kit` (DOM specs + `tool/ui_kit_shots/contrast.mjs`)
- **Parity** — `npm run parity:gate` (`tool/parity/verify-app-parity.mjs --gate 3`)

---

## Token (Layer 1 — `tokens/*.css`)

| # | Criterion | How it's verified |
| --- | --- | --- |
| T1 | Name is additive; no existing `--memox-*` renamed/removed | Diff review + Lint |
| T2 | Defined for **both** light (`:root`) and dark (`[data-theme='dark']`) where role is themed | `tokens/colors.css`, `tokens/elevation.css` review |
| T3 | Value-only change to an existing token keeps its role semantics | Token reviewer |
| T4 | Color/text roles pass **WCAG AA** in both themes | `tool/ui_kit_shots/contrast.mjs` (Kit) |
| T5 | Spacing values stay on the `{4,8,12,16,24,32,48}` scale; radius/stroke/size use existing scales | Token reviewer |
| T6 | Registered in `_ds_manifest.json` token inventory | manifest diff |
| T7 | Parity-neutral: existing 390×780 shots unchanged unless the value change is the intended visual delta | Parity |

**No component or screen may introduce a raw px/color** — every visual value resolves to
a token. That is the single hard gate that keeps Layer 1 the source of truth.

## Component (Layer 2 — `Mx*` in `components/`, styled in `components.css`)

| # | Criterion | How it's verified |
| --- | --- | --- |
| C1 | Stable PascalCase name + stable base class; variants are **modifiers**, never new names | Diff review + Lint |
| C2 | Consumes **only tokens** — no raw values in the component | Component reviewer + Lint |
| C3 | Full state matrix rendered: default / hover / press / focus / disabled + loading/empty/error where applicable | Kit gallery |
| C4 | Visible `:focus-visible` ring; touch target ≥ 44×44 | Component + Accessibility reviewer |
| C5 | `role` / `aria-*` correct (pixel-neutral) | Accessibility reviewer |
| C6 | Renders correctly in light **and** dark | Kit gallery (both themes) |
| C7 | Registered in `_ds_manifest.json` components list with `sourcePath` | manifest diff |
| C8 | Respects `prefers-reduced-motion` and the `[data-hc='true']` profile where it animates/relies on contrast | Component reviewer |

## Pattern (Layer 3 — feature + shared composites in `ui_kits/memox-app/`)

| # | Criterion | How it's verified |
| --- | --- | --- |
| P1 | Assembled **only** from `Mx*` components + kit-helpers — no loose card/button/layout markup | Pattern reviewer + Lint |
| P2 | Every meaningful node carries a stable `data-mx-node="<screen>/<node>"` id | Diff review |
| P3 | Ships the construction-contract state matrix (loading, normal/min/dense, empty, error, long text, large font, narrow, dark) + form submit lifecycle where relevant | Kit gallery + `specs/` |
| P4 | Has a DOM spec + rendered PNG under `ui_kits/memox-app/specs/` and `shots/` (light + dark) | Kit |
| P5 | Production screen pixel-matches its kit reference at **< 3%** per state × theme | Parity |
| P6 | Recurs in **≥ 3** features before promotion to core is considered (`component-promotion.md`) | Promotion review |
| P7 | Fixtures identical kit-side (`_features/<screen>/`) and app-side (`src/features/<feature>/ui/fixtures.ts`) | Parity (data-drift is a defect) |

---

## Cross-layer Definition of Done

A change is releasable only when: its layer's criteria pass; Lint + Kit + Parity are
green (or a divergence is registered in `parity-allowlist.json` **and**
`REMAINING-DIVERGENCES.md` with a written reason); the required `OWNERS.md` reviewer(s)
approved; and `CHANGELOG.md` records the change with its impact class
(additive / value-change / breaking).
