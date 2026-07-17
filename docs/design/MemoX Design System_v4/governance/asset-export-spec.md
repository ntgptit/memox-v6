# Asset export specification

> Closes audit items **KIT-14-05** (no brand logo/app-icon asset; no clear-space/min-size/
> dark-bg variant spec) and **KIT-45-05** (no asset export spec table with dimensions/
> scale/fallback; missing logo/app-icon).

Defines how each shipped asset is exported and consumed, and records the **logo /
app-icon gap** as a tracked deliverable (not a silent omission). Values are drawn from
`_ds_manifest.json`, `tokens/typography.css`, and the kit iconography section.

## Export spec table

| Asset | Type | Source | Format | Weights / sizes | Scale / DPR | Fallback | Consumer | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Plus Jakarta Sans** | Variable font | `fonts/PlusJakartaSans[wght].ttf` | TTF (variable, `wght` axis) | Weight range `200 800`; used at 400/500/600/700/800 (`--memox-font-weight-*`) | N/A (vector) | `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif` (`--memox-font-sans`) | RN font asset + `@font-face` in `tokens/typography.css` | **Current** — self-hosted, shipped |
| **Material Symbols Rounded** | Icon font | Google Fonts CDN | Variable icon font (weight 400, FILL 0) | Rendered at `--memox-icon-size-sm/md/lg/xl` = 18/22/28/32px | N/A (vector) | OS glyph fallback if CDN unavailable; self-host if offline needed | Ligature spans in kit HTML; RN icon font in production | **Current** — CDN (not self-hosted; see gap G2) |
| **Avatar images** | Raster (content, not brand) | Placeholder/user-provided | Sized by token | `--memox-comp-avatar-sm/md/lg` = 32/44/64px | 1× / 2× per DPR (kit shoots at 2×) | Initials in `MxAvatar` when no image | `MxAvatar` | **Current** — content asset, no brand export |
| **Wordmark** | Vector wordmark (MemoX's own type) | `assets/memox-wordmark.svg` (light) + `assets/memox-wordmark-dark.svg` (dark) | SVG master (outline before static ship); PNG @1×/2×/3× on export | Set in Plus Jakarta Sans **Extrabold** (800); deep-violet `#4b3a8c` light / near-white `#f6f5fc` dark | 1×/2×/3× (kit shoots 2×) | Plus Jakarta Sans Extrabold live text if the asset is unavailable | Splash / about / header lockups | **Current** — wordmark shipped; see §Wordmark spec |
| **Brand icon (bespoke mark)** | Vector mark | — none provided — | (target: SVG + PNG @1×/2×/3×) | (target: min-size + clear-space specs) | (target: 1×/2×/3×) | Wordmark stands alone until a bespoke icon exists | Icon lockups | **Gap G1 — pending** (typographic wordmark in place) |
| **App icon** | Raster/vector | — none provided — | (target: iOS/Android icon sets + adaptive icon) | (target: full platform size matrix) | (target: per-platform density buckets) | none | Launcher / store | **Gap G1 — missing** |

## Wordmark spec (KIT-14-05)

The **MemoX wordmark** is MemoX's own typographic logo — the product name set in the kit's
typeface. It is legitimate to author (it is not a third-party brand). It **remains a
typographic wordmark pending a bespoke brand icon** (tracked as Gap G1 below); the wordmark
is not a substitute for that icon, only the current brand lockup.

**Assets:** `assets/memox-wordmark.svg` (light usage) and `assets/memox-wordmark-dark.svg`
(light-on-dark usage). Both are single-line `<text>` set in Plus Jakarta Sans weight 800 at
a 452×128 viewBox; outline the text against the Plus Jakarta Sans master before shipping as
a fully static (font-independent) asset.

| Property | Spec |
| --- | --- |
| **Typeface / weight** | Plus Jakarta Sans **Extrabold (800)** — `--memox-font-weight-800`, self-hosted `fonts/PlusJakartaSans[wght].ttf`. |
| **Colour — light** | Deep-violet `--memox-primary` **`#4b3a8c`** on light surfaces (`--memox-bg` `#f6f5fc` / `--memox-surface` `#ffffff`). |
| **Colour — dark** | Near-white **`#f6f5fc`** on the dark canvas (`--memox-bg` `#141220`), mirroring the light treatment (`memox-wordmark-dark.svg`). |
| **Clear-space** | Minimum padding on all sides = the cap-height of the wordmark, i.e. **≈ 0.7× the wordmark height** (equivalently one `M`-width). Keep other elements outside this zone. |
| **Minimum size** | Legible portrait-phone floor: **height ≥ 20px** (≈ 72px wide) on screen; below this use the future brand icon instead. |
| **Light/dark usage** | Use `memox-wordmark.svg` on light surfaces and any surface lighter than `--memox-surface-muted`; use `memox-wordmark-dark.svg` on `[data-theme='dark']` and any surface darker than `--memox-primary`. Choose by the surface luminance behind the mark, per `guidelines/system-ui.md` §1. |
| **Do-not** | Do not recolour outside the two brand tones, stretch/skew, re-space the letters, add effects, or place the light mark on a dark surface (and vice-versa). Changing the wordmark *rendering* is fine; the letterforms and spacing are the fixed lockup. |

## Tracked gaps

- **G1 — bespoke brand icon / app-icon (P2, EXC-02).** The typographic **wordmark now
  ships** (see §Wordmark spec), but no bespoke **brand icon** or **app-icon** was provided.
  The wordmark is the current lockup, not the icon. When a brand icon / app-icon is
  supplied, this spec must be extended with:
  - **Clear-space:** minimum padding around the mark expressed in a token multiple.
  - **Minimum size:** smallest legible render (portrait phone context) in px.
  - **Dark-bg variant:** an explicit mark/wordmark treatment for the `[data-theme='dark']`
    canvas (`--memox-bg` `#141220`), mirroring the light treatment on `#f6f5fc`.
  - **Export matrix:** SVG master + PNG @1×/2×/3× (kit shoots at 2× DPR) and the full iOS
    + Android app-icon/adaptive-icon size sets.
  Tracked in `exception-register.md` (EXC-02); owner: Design System team (design owner).

- **G2 — icon font self-hosting.** Material Symbols Rounded is loaded from the Google
  Fonts CDN. If an offline/self-hosted build is required, self-host the variable icon
  font and document its export here (per `readme.md` iconography guidance).

## Export rules

- **No raw brand values in assets** beyond the token layer — asset dimensions reference
  tokens (`--memox-comp-avatar-*`, `--memox-icon-size-*`) rather than literals where the
  asset is sized by the system.
- **DPR:** the kit renders/shoots at **2× DPR**; raster exports provide at least @1× and
  @2×, adding @3× for app icons.
- **Fallback is mandatory** for every font/icon asset so a missing CDN or font file
  degrades gracefully.
