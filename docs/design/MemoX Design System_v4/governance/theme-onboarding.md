# New-theme onboarding checklist

> Closes audit item **KIT-07-05** (a contrast regression gate exists but there was no
> new-theme onboarding checklist and no sample completed run showing the end-to-end flow).

Adding a theme means supplying a new set of **values** for the existing `--memox-*` role
tokens under a new theme selector — never new token *names*. This is the additive,
frozen-identifier path from `CONTRIBUTING.md`: light lives in `:root`, dark in
`[data-theme='dark']`, and any further theme (e.g. a future high-contrast or brand skin)
is a new attribute selector layered on top (`[data-hc='true']`, etc.). A theme is not
"done" until every gate below passes in that theme.

---

## Checklist (run in order — each step blocks the next)

1. **Define token values.**
   - Copy the full role list from `tokens/colors.css` `:root` and give each role a value
     under the new selector. Cover **every** role a component reads — surfaces
     (`--memox-bg`, `--memox-surface*`), text (`--memox-text*`, `--memox-on-*`), brand
     (`--memox-primary*`, `--memox-accent*`), semantic (`--memox-success/warning/error/info`
     and their `-soft`/`-on-*` pairs), borders (`--memox-border*`), focus
     (`--memox-focus-ring`, `--memox-ring-focus`), and the data-viz namespace
     (`--memox-viz-1…6`). A role left undefined falls through to `:root` and is a defect.
   - **No new names, no raw values above the token layer.** You change values only.

2. **Run the contrast gate (light + dark discipline, per theme).**
   - `node tool/ui_kit_shots/contrast.mjs` (wired into `npm run verify:ui-kit`).
   - Every text/icon role must pass **WCAG AA** against its background in the new theme:
     normal text ≥ 4.5:1, large text / UI ≥ 3:1, focus ring ≥ 3:1 against both the surface
     and the focused control. Fix values and re-run until zero failures. This is the
     regression gate — do not proceed on a red run.

3. **Capture shots.**
   - Add the theme to the shot matrix and run `npm run golden:update` (kit) so every
     canonical state renders in the new theme at the shared **390 × 780** frame, exactly
     as light + dark do today (168 states each). No fixture data may differ between
     themes — only token values change.

4. **Parity check.**
   - `npm run parity:gate` (`tool/parity/verify-app-parity.mjs --gate 3`). Each state ×
     theme pair must be **< 3%** mismatch against its kit reference shot. Diagnose reds
     with the diff PNGs in `tool/parity/out/diff/`, fix, re-shoot, re-run. A pair may only
     exceed 3% through `parity-allowlist.json` with a matching `exception-register.md` row
     and a `REMAINING-DIVERGENCES.md` section — reserved for semantic divergence, never
     styling drift.

5. **Record + sign off.**
   - Add a `CHANGELOG.md` entry (`[value]` — new theme values, names/ids stable), update
     `SCOPE.md` (move the theme from Planned → Supported with evidence), and get the
     `OWNERS.md` theme owner's approval in `release-signoff.md`.

**Definition of done:** steps 1–5 complete, contrast gate green for the theme, every
state × theme parity pair `< 3%` (or allowlisted with a reason), CHANGELOG + SCOPE + sign-off
updated. Never "looks right" — cite the gate.

---

## Worked sample run — onboarding the existing **dark** theme

This is a completed, real run of the checklist for the theme already shipped
(`[data-theme='dark']`), shown so the process is executable, not abstract.

| Step | Action taken | Result / evidence |
| --- | --- | --- |
| 1. Define values | Every `:root` role redefined under `[data-theme='dark']` in `tokens/colors.css` — e.g. `--memox-bg #f6f5fc → #141220`, `--memox-surface #ffffff → #252338`, `--memox-primary-strong #3b2d72 → #b4aadd`, `--memox-accent → #a88fff`, `--memox-viz-1…6` remapped, focus roles kept. | `tokens/colors.css` `[data-theme='dark']` block — full role parity with `:root`, zero fall-through. |
| 2. Contrast gate | `node tool/ui_kit_shots/contrast.mjs` over all dark states. | **PASS** — all text/icon roles ≥ AA on the `#141220` canvas and raised surfaces; focus ring ≥ 3:1. |
| 3. Capture shots | Dark added to the shot matrix; `npm run golden:update`. | **168 dark shots** produced at 390×780, mirroring the 168 light states (336 total). |
| 4. Parity check | `npm run parity:gate`. | Every dark state × theme pair **< 3%** except the two documented semantic divergences (EXC-01, EXC-04) which are allowlisted with reasons. |
| 5. Record + sign off | Dark listed in `SCOPE.md` Supported (Themes row), CHANGELOG v4 foundation notes the dark role set, release sign-off references the dark coverage. | `SCOPE.md` §Supported; `CHANGELOG.md` [v4] Foundation; `release-signoff.md`. |

Reproduce this exact sequence for any future theme; a new theme is accepted only when its
own run of this table is green end to end.
