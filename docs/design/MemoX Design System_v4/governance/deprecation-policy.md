# Deprecation policy & register

> Closes audit items **KIT-47-02** (structured deprecation table with replacement/reason/
> since-version/removal-target), **KIT-47-03** (lint rule blocking new usage of a
> deprecated artifact), **KIT-47-04** (migration map old→new with visual/behavior diffs),
> **KIT-47-05** (usage-scan-before-removal / usage=0 report), and **KIT-47-06**
> (duplicate-resolution / canonical-choice record).

## Policy

The kit's identifiers are **additive-only and frozen** (see `versioning.md`). Nothing is
ever deleted abruptly. The only sanctioned path away from an artifact is:

1. **Add the replacement** (additive — new token / `Mx*` / class / composite).
2. **Deprecate** the old artifact by adding a row to the register below with
   *replacement · reason · since-version · removal-target*.
3. **Block new usage.** A deprecated artifact is added to the adherence lint deny-list in
   `_adherence.oxlintrc.json` (`no-restricted-imports` for composites/components, and a
   restricted-syntax/forbid rule for a deprecated token or class) so **new** references
   fail lint while **existing** references keep working. Deprecation never breaks a
   consumer at deprecation time.
4. **Write a migration map** (old→new) naming the concrete visual and behavioral diffs —
   see the template below. Attach it to the `CHANGELOG.md` entry.
5. **Usage scan before removal.** Removal happens in a later **major** release and only
   after a documented **usage=0** scan across `components/`, `ui_kits/memox-app/`, and
   downstream consumers. Record the scan (date, command, result) in the register row's
   removal note. No usage=0 report ⇒ no removal.
6. **Duplicate resolution.** When two artifacts overlap, pick one **canonical**, deprecate
   the other pointing at the canonical, and record the choice (below + `duplicate-scan.md`).

## Deprecation register

Columns: **Artifact** · **Kind** · **Replacement** · **Reason** · **Since** · **Removal
target** · **Lint block** · **Status**.

| Artifact | Kind | Replacement | Reason | Since | Removal target | Lint block | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tokyo admin-dashboard color *values* (indigo/violet/green/coral/amber/cyan sampled from `ntgptit/tokyo-react-admin-dashboard`) | Color values (no names) | Deep-violet palette in `tokens/colors.css` (`--memox-primary` `#4b3a8c`, `--memox-accent` `#7355d6`/`#a88fff`, semantic roles) | Rebrand to MemoX's own deep-violet identity; Tokyo values were a placeholder sample, never MemoX's brand | v4 (pre-freeze) | **Removed at v4 freeze** — values fully migrated; do not reintroduce | Any PR reintroducing the legacy hexes is rejected in review; token values are contrast-checked by `tool/ui_kit_shots/contrast.mjs` | **Migrated / retired** |
| `--memox-appbar-lg-height` (`112px`) — large/hero app bar metric | Token (value present, unused) | `--memox-appbar-height` (`56px`) via the single compact `MxContextualAppBar` | The large/hero app bar was retired; only the compact 56px contextual bar is used | v4 | v5 (only after usage=0 scan confirms no consumer references it) | Token kept for back-compat; new screens must use `--memox-appbar-height` | **Deprecated (kept for compatibility)** |
| `flashcard-list/convert-*` state/id family | Prototype state | Create an Empty Parent Deck and use a separately specified transfer flow | Product decision makes Empty/Leaf/Parent exclusive; implicit Leaf→Parent conversion is not a valid business operation | v4.1 rebaseline | v5 only after downstream usage=0; frozen ids remain fail-closed until then | State excluded from active spec/route registry; compatibility renderer performs no mutation | **Deprecated, non-routable** |

> Note on the Tokyo entry: only color **values** were ever involved — no token name,
> component name/class, or `data-mx-node` id came from Tokyo, so nothing in the frozen
> identifier contract is affected. This is a value migration, recorded here for lineage.

## Migration map template (old → new)

Every deprecation must ship a filled map so consumers see the concrete diffs, not prose:

| Old artifact | New artifact | Visual diff | Behavior diff | Consumer action |
| --- | --- | --- | --- | --- |
| `<old name/value>` | `<new name/value>` | e.g. hue shifts from X to deep violet; contrast improves to AA | e.g. none / focus ring color changes | e.g. rebind theme constant; re-shoot parity |

Worked example — Tokyo values → deep violet:

| Old | New | Visual diff | Behavior diff | Consumer action |
| --- | --- | --- | --- | --- |
| Tokyo indigo/violet sampled values | `--memox-primary` `#4b3a8c`, `--memox-accent` `#7355d6`/`#a88fff` | Warmer, deeper violet; calmer nocturnal dark theme; passes WCAG AA both themes | None — same roles, same token names | Re-map theme constants to the deep-violet token values; re-shoot parity |

## Usage-scan-before-removal record

Removal of any deprecated artifact requires a recorded scan proving usage=0:

- **Scope:** `components/`, `ui_kits/memox-app/` (`_features/**`, `_shared/**`,
  `kit-helpers.jsx`), `_ds_manifest.json`, and downstream consumers.
- **Mechanism:** repository-wide grep of the artifact name/token + the adherence lint
  deny-list report (`_adherence.oxlintrc.json`).
- **Record:** date, exact command/output, result. Removal proceeds only on a clean
  usage=0 result and is announced in `CHANGELOG.md` as **[breaking]** in a major release.

_No artifact is currently scheduled for removal in a pending release; the two register
rows above are retained for compatibility/lineage._
