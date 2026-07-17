# Coverage report

> Closes audit item **KIT-48-04** (coverage evidence — shots/specs/contrast — existed but
> was never aggregated into a released coverage report).

Aggregates the kit's existing verification evidence into one released view. Counts are
taken from the kit sources at the v4 baseline; the authoritative per-screen list lives in
`ui_kits/memox-app/specs/INDEX.md` (generated from `tool/ui_kit_shots/registry.mjs`).
Re-generate with the commands in each section — do not hand-edit counts elsewhere.

## Rendered-state coverage (kit gallery)

| Metric | Count | Source |
| --- | --- | --- |
| Screens (feature modules) | **26** | `ui_kits/memox-app/_features/` |
| DOM specs | **26** | `ui_kits/memox-app/specs/` |
| Rendered shots (total) | **336** | `ui_kits/memox-app/shots/*.png` |
| — light | **168** | `shots/*--light.png` |
| — dark | **168** | `shots/*--dark.png` |
| Theme parity | **1:1** light↔dark for every state | 168 = 168 |

Every screen is rendered through its full state matrix in **both** themes (per the mobile
UI construction contract). Regenerate: `npm run verify:ui-kit`.

## Component & token coverage

| Metric | Count | Source |
| --- | --- | --- |
| Frozen `Mx*` components | **18** | `components/` (core 8, surfaces 6, navigation 4) |
| Feature + shared composites registered | **80+** | `_ds_manifest.json` `components[]` |
| Token files | **11** | `tokens/` (colors, typography, spacing, component, opacity, radius, stroke, size, icon-size, elevation, motion) |
| Tokens inventoried | **190+** | `_ds_manifest.json` `tokens[]` |

## Contrast (accessibility) coverage

| Metric | Value | Source |
| --- | --- | --- |
| Contrast checker | `tool/ui_kit_shots/contrast.mjs` | wired into `npm run verify:ui-kit` |
| Standard | WCAG AA, **light + dark** | `readme.md` caveats |
| Scope | All text/icon color roles in `tokens/colors.css` | both `:root` and `[data-theme='dark']` |
| Status | Passing at v4 baseline | `verify:ui-kit` |

Regenerate: `node tool/ui_kit_shots/contrast.mjs`.

## Kit ↔ app parity coverage

| Metric | Value | Source |
| --- | --- | --- |
| App-golden baseline shots | **165** | `tool/app_golden/baseline/` |
| Compared pairs | **41** | `tool/parity/verify-app-parity.mjs` |
| Pairs below the 3% gate | **40** | `REMAINING-DIVERGENCES.md` |
| Pairs above the gate | **1** (`deck-settings--move` ~10%, **semantic by design**) | `parity-allowlist.json` + `exception-register.md` EXC-01 |
| Frame | 390 × 780 | parity gate |
| Comparison gaps (no kit counterpart) | 2 (`deck-content-choice--named`, `shell-dashboard--loaded`) | `REMAINING-DIVERGENCES.md`, EXC-05 |

Regenerate: `npm run parity:gate` (gate) / `npm run parity:app` (report).

## Responsive, text-scaling, script & keyboard coverage (audit-v5 remediation)

Added in the audit-v5 remediation loop to close the render / runtime-evidence gaps across
KIT-09 / 11 / 21 / 25 / 35 / 36 / 37 / 41 / 42. Regenerate with the commands noted.

| Axis | Coverage | Evidence | Source |
| --- | --- | --- | --- |
| Phone viewport range | 320 / 360 / 390 / 430 px (min → default → max) | full matrix renders every state at all four widths; 0 unaccepted overflow at any width | `tool/ui_kit_shots/shoot.mjs` `WIDTHS`; KIT-11-01 |
| Text scaling | 100 % / 130 % / 150 % / **200 %** | full matrix at every width × theme; the only 200 % overflow — the confirm-dialog action row on a 320 px frame — is fixed by the wrapping `.mx-dialog-actions` row | `shoot.mjs` `FONT_SCALES`; KIT-09-05 / 21-06 / 42-05 |
| Per-script rendering | Vietnamese diacritics + CJK (Korean / Japanese / Chinese) + mixed-script | `shots/languages--scripts--{light,dark}.png` (wired to `--memox-font-cjk`); Korean + Vietnamese in `flashcard-editor`, Korean + Japanese in `languages--list` | `tokens/typography.css` `--memox-font-cjk` / `--memox-font-vietnamese`; KIT-09-04 / 37-02 |
| Combined worst-case | dir = rtl + longest-content state + 200 % @ 320 px | `out/rtl/*.png` — 8 renders (4 screens × 2 themes), 0 blockers; app bar / breadcrumb / chips / cards mirror | `tool/ui_kit_shots/rtl-stress.mjs`; KIT-41-06 |
| Keyboard / screen-reader | full-task focus walk (Tab / Shift+Tab / Enter / Esc) + axe role/name/aria | `tool/a11y/focus-order.*.json`, `axe-report.json`, `summary.json` — no trap, reversible, primary CTA reachable, all stops named, 0 serious role/name/aria | `tool/a11y/keyboard-walkthrough.mjs`; KIT-42-02 |

Regenerate: `node tool/ui_kit_shots/shoot.mjs` (matrix incl. 200 %) · `node tool/ui_kit_shots/rtl-stress.mjs` · `node tool/a11y/keyboard-walkthrough.mjs`.

## Coverage summary

- **Visual states:** 26 screens × light+dark fully rendered and spec'd (336 shots / 26
  specs) — no screen ships happy-path-only.
- **Accessibility:** all color roles contrast-checked AA in both themes.
- **Parity:** 40/41 production pairs under 3%; the single over-gate pair is a documented
  semantic divergence, not styling drift.
- **Responsive / scaling / script / RTL / keyboard:** now covered by the audit-v5 remediation
  (section above) — phone viewport range, 200 % text scaling, per-script (Vietnamese + CJK)
  rendering, the combined dir=rtl + long + 200 % worst-case, and the keyboard/focus walkthrough.
- **Open coverage gaps** (feed `release-signoff.md`): logo/app-icon assets absent
  (`asset-export-spec.md`, P2 with owner + target) and 2 uncomparable parity pairs (EXC-05).
