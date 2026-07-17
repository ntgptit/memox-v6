# Contributing to the MemoX Design System

> Closes audit item **KIT-46-02** (no contribution template covering use-cases,
> duplicate-check, required states, a11y, and docs).

This kit is a **frozen-identifier** system. Read `../readme.md` and `../SKILL.md`
before contributing. The golden rule holds for every change:

> Changing a **value** is free; changing a **name or id** breaks the system.

Token names (`--memox-*`), `Mx*` component names, base CSS classes, and
`data-mx-node="<screen>/<node>"` ids are an **additive-only** contract. You may add new
tokens/classes/variants/attributes and you may change token *values*; you must never
rename or remove an existing identifier. See `deprecation-policy.md` for the only
sanctioned path toward removal.

---

## Contribution template

Open every proposal (issue or PR description) with this template filled in. A PR that
omits a section is not ready for review.

### 1. Use-cases

- **Problem / need.** What screen or interaction requires this? Cite the feature under
  `ui_kits/memox-app/_features/<screen>/` or the concrete product need.
- **Recurrence.** Where does it appear? A new *core component* or *shared composite*
  must show **≥ 2 (composite) or ≥ 3 (core promotion)** distinct feature usages — see
  `component-promotion.md`. One-off UI stays a feature-local composite.
- **Layer.** State which layer you are changing — Token, Component, or Pattern. No
  layer-skipping and no raw visual values above the token layer.

### 2. Duplicate check (required)

- Search existing tokens (`tokens/*.css`), the `Mx*` family (`components/`), and shared
  composites (`ui_kits/memox-app/_shared/`) for something that already covers the need.
- Run the adherence lint (`_adherence.oxlintrc.json`) and review `duplicate-scan.md`.
- If a near-duplicate exists, **extend it** (new value / variant / modifier) rather than
  adding a parallel name. Record the check outcome in the PR ("searched X, closest was
  Y, chose to extend/add because Z"). Intentional semantic aliases (e.g. `--memox-info`
  = `--memox-primary` value) are allowed but must be justified.

### 3. Required states

New or changed components/patterns must ship their full state matrix, per
`../../mobile-ui-construction-contract.md` and `acceptance-criteria.md`:

- loading, loaded (normal / min / dense), empty, recoverable error, long text, large
  font, narrow device, and **dark mode**;
- for forms: validation error, disabled, submitting, failure, success.

Add each canonical state to the kit gallery (`ui_kits/memox-app/`) and, for production
screens, to `tool/app_golden/shoot.mjs` TARGETS. Happy-path-only changes are rejected.

### 4. Accessibility (a11y)

- **Contrast:** all text/icon roles pass WCAG AA in **both** light and dark. Verify with
  `node tool/ui_kit_shots/contrast.mjs` (wired into `npm run verify:ui-kit`).
- **Focus:** interactive elements expose a visible `:focus-visible` ring
  (`--memox-focus-ring` / `--memox-ring-focus`).
- **Touch target:** ≥ 44×44 (kit baseline `--memox-touch-min: 48px`).
- **Semantics:** correct `role` / `aria-*`; these never change rendered pixels.
- **Reduced motion / high contrast:** respect `prefers-reduced-motion`
  (`--memox-duration-none`) and the additive `[data-hc='true']` profile where relevant.

### 5. Docs

- Update the component/token `.prompt.md` or spec next to the source.
- Add an entry to `../CHANGELOG.md` (additive vs. value-change vs. breaking).
- If anything is deprecated, update `deprecation-policy.md`'s table.
- If you introduce a sanctioned exception, register it in `exception-register.md`
  with owner, target, and expiry.

---

## Review + verification gates

A contribution merges only when:

1. **Adherence lint** passes (`_adherence.oxlintrc.json`).
2. **Kit verification** passes — `npm run verify:ui-kit` (DOM specs + contrast).
3. **Parity gate** passes for any production screen — `npm run parity:gate`
   (`< 3%` mismatch per state × theme; see `../readme.md` parity contract).
4. The **required reviewer role(s)** in `OWNERS.md` approve.
5. Acceptance criteria in `acceptance-criteria.md` for the affected layer are met.

Never sign off with "looks good / clean / polished." Cite the specific rule, fixture,
or gate that passed.
