# Versioning, approval & release process

> Closes audit items **KIT-46-04** (version-bump / approval / migration-note process for
> breaking changes), **KIT-46-05** (release cadence + consumer notification), and
> **KIT-48-05** (version metadata / changelog for release).

## Current version

- **Kit version:** `v4` — the frozen snapshot in `docs/design/MemoX Design System_v4/`.
  The major version is encoded in the folder name and by the frozen/additive-only policy
  in every `tokens/*.css` header.
- **Namespace:** `MemoXDesignSystem_2ffa54` (kit HTML / `@dsCard`).
- **Next milestone:** `v4.1` kit freeze — the target milestone for the open audit items
  in `../../mobile-design-kit-audit-v5/issue-register.md`.

Version history lives in `../CHANGELOG.md`. Every release records its version there.

## Semantic version policy (mapped to the frozen-identifier contract)

The kit's identifier contract makes the version rules concrete:

| Bump | Trigger | Identifier impact | Examples |
| --- | --- | --- | --- |
| **Patch** (`vX.Y.Z`) | Value-only change; docs; fixture copy; new shots | None — names/ids stable | Recolor a token value, tune a shadow, fix copy |
| **Minor** (`vX.Y`) | **Additive** — new token / `Mx*` component / variant / `data-mx-node` id / composite | Additive only; nothing renamed/removed | Add `--memox-viz-*`, add `[data-hc='true']`, add a variant |
| **Major** (`vX`) | **Breaking** — rename/remove any token, `Mx*` name, base class, or `data-mx-node` id | Contract break | Retiring a component name; renaming a token |

Because names are frozen additive-only, **most work is patch or minor**. A major bump is
exceptional and follows the breaking-change process below.

## Approval

- **Patch / minor:** the required reviewer role(s) in `OWNERS.md` for the touched area,
  plus green Lint + Kit + Parity gates (see `acceptance-criteria.md`).
- **Major / breaking:** additionally requires all three sign-off owners
  (design + accessibility + governance) to approve in `release-signoff.md`, plus a
  migration note (below) and a deprecation entry (`deprecation-policy.md`).

## Breaking-change process (major bump)

1. **Deprecate first, never remove abruptly.** Add the replacement (additive), then mark
   the old artifact deprecated in `deprecation-policy.md` with replacement, reason,
   since-version, and removal-target. Lint blocks *new* usage of the deprecated artifact.
2. **Usage scan before removal.** Removal is allowed only after a documented usage=0 scan
   across `components/`, `ui_kits/memox-app/`, and consumers (see
   `duplicate-scan.md` for the scan mechanism). Record the scan result.
3. **Write a migration map** — an old→new table naming the visual and behavioral diffs
   (not prose): what the consumer must change, and what will look/behave differently.
   Attach it to the CHANGELOG entry and the release note.
4. **Bump the major version**, update `_ds_manifest.json` and the folder/version marker.
5. **Sign-off** in `release-signoff.md` by all three owners.

## Release cadence

- **Frozen baseline releases** (major/minor) are cut on demand when a batch of additive
  work or a breaking migration is ready — not on a fixed calendar. `v4` is the current
  baseline; `v4.1` is the next.
- **Patch releases** (value/doc/fixture) roll up continuously as gates stay green.
- Each release is a snapshot: a version entry in `../CHANGELOG.md`, a passing
  `verify:ui-kit` + `parity:gate`, and a `release-signoff.md` record.

## Consumer notification

When a release ships, consumers (the MemoX React Native app and any downstream mapping of
tokens → theme constants / base classes → `Mx*` RN components) are notified via:

1. the **`../CHANGELOG.md`** entry (source of truth), tagged with impact class;
2. for **minor/major**, a short release note summarizing new artifacts and — for major —
   the migration map and deprecation timeline;
3. **breaking changes** additionally carry the removal-target version so consumers can
   plan migration before the deprecated artifact is removed.

Silent value changes that alter rendered pixels are still announced, because the parity
gate treats consumer shots as a contract.
