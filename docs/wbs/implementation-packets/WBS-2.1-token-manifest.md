# WBS 2.1 — Token inventory/mapping manifest implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `0.2`, `1.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-2.1-01` |
| Test | `TEST-WBS-2.1-01` |

## Canonical inputs

- `docs/design/MemoX Design System_v4/tokens/*.css` — 12 files, the frozen
  `--memox-*` token vocabulary (golden rule: values are free to change,
  names/ids are additive-only).
- `docs/design/MemoX Design System_v4/readme.md` + `SCOPE.md` token contract.
- WBS §4.3 target tree: token Dart owners live under
  `lib/core/theme/tokens/`.
- `tool/verify/run.mjs` — the canonical gate that must run the check.

## Scope

Create:

- `tool/design/token_manifest.mjs` — parser + generator + checker:
  - parses every `--memox-*` declaration across the kit's `tokens/*.css`
    (selector-context aware, so light/dark redeclaration is legal but a
    duplicate inside one selector block fails);
  - derives each token's Dart owner file/symbol from a fixed family rule
    (`colors.css → app_colors.dart` …, `high-contrast.css` last in
    precedence because it only overrides);
  - `--write` regenerates the manifest; `--check` reconciles CSS ↔ committed
    manifest and fails on missing, orphaned, duplicate or drifted entries.
- `docs/design/token-manifest.json` — generated, committed frozen-name
  snapshot: 207 tokens, each with `owner` (Dart file), `symbol`, owning
  `wbs` item (2.2 = 75, 2.3 = 27, 2.4 = 91, 2.5 = 14) and `sources`.

Modify:

- `tool/verify/run.mjs` — new `design token manifest` step running
  `--check` in every mode (docs/quick/full).

Out of scope: the Dart token files themselves (owned by 2.2–2.5; the
manifest is their plan-of-record), high-contrast value mapping (2.9),
theme extensions/assembly (2.6–2.7).

## Enforcement semantics

| Change in kit CSS | Checker outcome |
| --- | --- |
| New token added | `missing from manifest` failure until `--write` is rerun and reviewed in the same change (additive change is explicit) |
| Token renamed | missing + orphaned pair — fails; renames are forbidden for frozen names |
| Token deleted | `orphaned manifest entry` failure — deletion requires an explicit reviewed manifest change |
| Same token redeclared for dark/high-contrast | Legal; recorded in `sources` |
| Duplicate declaration inside one selector block | Failure |
| Manifest hand-edited out of sync | `manifest drift` failure |

## Acceptance and test procedure

`AC-WBS-2.1-01` is true only when:

1. Every `--memox-*` declaration in the kit maps to exactly one manifest
   entry with a Dart owner path under `lib/core/theme/tokens/` and a
   deterministic symbol name.
2. The checker fails on missing/orphaned/duplicate/drifted entries with an
   actionable message.
3. The canonical verifier runs the check in all modes.
4. Full canonical gate passes.

`TEST-WBS-2.1-01`:

- `node tool/design/token_manifest.mjs --check` passes on the committed
  manifest (exercised by every verifier run).
- Manual negative evidence recorded at review: temporarily renaming one
  token in a scratch copy produces the missing+orphaned failure pair.
- Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Success: record register evidence, mark `2.1` Done, then author packets
  for `2.2`–`2.5` in order.
