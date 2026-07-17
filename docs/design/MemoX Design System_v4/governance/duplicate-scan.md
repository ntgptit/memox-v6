# Duplicate / near-duplicate scan process

> Closes audit item **KIT-47-01** (no periodic duplicate-scan tooling; manual scan found
> only intentional semantic aliases). Related: `deprecation-policy.md` (KIT-47-06
> duplicate resolution).

## Why

A frozen additive-only system accumulates tokens, `Mx*` components, and composites over
time. Without a duplicate scan, contributors add a parallel name for something that
already exists, fragmenting the source of truth. This process detects duplicates and
near-duplicates and routes them to canonical resolution.

## What counts as a duplicate

- **Exact duplicate** — two tokens with the same value and the same role, or two
  composites with the same anatomy.
- **Near-duplicate** — values close enough to be indistinguishable in the 390×780 render,
  or components differing only by a variant that should be a modifier.
- **Intentional semantic alias** — *not* a duplicate: two names that share a value on
  purpose because they carry different semantics (e.g. `--memox-info` uses the same value
  as `--memox-primary`; `--memox-radius-chip` = `--memox-radius-pill` = `999px`). These
  are allowed and documented, not merged.

## Scan mechanism

1. **Adherence lint** — `_adherence.oxlintrc.json` (oxlint, `react` + `import` plugins).
   Its `no-restricted-imports` patterns constrain cross-layer/deep imports of
   `components/**` and `ui_kits/memox-app/_features/**`, and `react/forbid-elements`
   guards raw-element usage. Run via `npm run lint`. This catches structural
   layer-skipping and unsanctioned deep imports that often accompany a duplicate.
2. **Audit validator** — the kit verification tooling under `tool/ui_kit_shots/`
   (`verify.mjs`, `contrast.mjs`) plus the audit ledger in
   `../../mobile-design-kit-audit-v5/`, which enumerate tokens/components and flag
   inconsistencies. `_ds_manifest.json` is the canonical inventory the scan diffs against.
3. **Manual token/composite sweep** — grep `tokens/*.css` for equal values across roles,
   and compare `_shared/` composites against `components/` for overlapping anatomy.

## Cadence

- **On every PR** touching `tokens/`, `components/`, or `ui_kits/memox-app/_shared/` —
  the contributor runs the duplicate check (`CONTRIBUTING.md` §2) and records the outcome.
- **Per release** — a full sweep before a minor/major bump, recorded in `CHANGELOG.md`.

## Resolution (when a real duplicate is found)

Follow `deprecation-policy.md`: choose the **canonical** artifact, deprecate the other
(replacement/reason/since/removal-target), add it to the lint deny-list to block new
usage, write the old→new migration map, and update `_ds_manifest.json`. Record the
canonical choice here.

## Latest scan result

**Manual + lint scan (v4 baseline / audit-remediation batch): no unintended duplicates.**
The only value-sharing found is **intentional semantic aliases**, kept by design:

| Names sharing a value | Value | Why it's an alias, not a duplicate |
| --- | --- | --- |
| `--memox-info` / `--memox-primary` (light) | `#4b3a8c` | Info semantics reuse the brand hue on purpose |
| `--memox-primary-soft` / `--memox-surface-muted` (light) | `#f1eff9` | Soft-brand tint intentionally equals the muted surface tone |
| `--memox-radius-chip` / `--memox-radius-pill` | `999px` | Distinct roles (chip vs. pill), same fully-rounded value |
| `--memox-radius-full` | `9999px` | Separate "full" role; not merged with chip/pill |
| `--memox-surface` / `--memox-surface-raised` / `--memox-on-primary` (light) | `#ffffff` | Different roles that happen to be white in light theme; diverge in dark |

No merges were required. Recurring `_shared` dialog/sheet composites are evaluated for
core promotion separately in `component-promotion.md` (that is a promotion question, not
a duplicate question).
