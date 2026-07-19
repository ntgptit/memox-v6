# WBS 3.15 — Kit visual parity gate packet

| Field | Value |
| --- | --- |
| Status | **In progress** — child A Done (2026-07-19); B pending |
| Owner/domain | Design system / QA |
| Depends on | `3.12` — Done |
| Decision gates | Owner rule (2026-07-19): screen-changing PRs merge only with parity evidence **<3%** |
| Acceptance | `AC-WBS-3.15-01` |
| Test | `TEST-WBS-3.15-01` |

## Canonical inputs

- Owner directive (2026-07-19): compare Flutter screens against the
  design kit before merging; diff must be under 3% to pass; cover the
  already-shipped screens retroactively.
- The kit's canonical shot matrix:
  `ui_kits/memox-app/shots/*.png` — 219 states × light/dark at 390
  logical px (2× PNGs); `create-deck.md` §"Tất cả canonical state đạt
  parity dưới 3%".

## Child boundaries

| Child | Scope |
| --- | --- |
| **A** | Parity harness + process rule + baseline measurements |
| **B** | Retro coverage: bring every shipped screen state under 3% (fix styling), convert probes into enforcing tests per state × theme |

## Child A — harness + baseline (Done, 2026-07-19)

- `test/support/kit_parity.dart` — the in-test harness: loads the real
  Plus Jakarta Sans font (kit-true text), sizes the view to the kit
  shot (2× DPR), captures the live render and pixel-diffs against the
  shot with a per-channel anti-aliasing tolerance; returns the
  differing-pixel ratio.
- `test/presentation/parity/kit_parity_probe_test.dart` — measurement
  probes printing current ratios.
- **Baseline measured** (fix backlog for child B):

| Screen state | Current diff | Target |
| --- | --- | --- |
| `create-deck-firstrun--landing--light` | 12.17% | <3% |
| `library--empty--light` | 11.48% | <3% |
| (remaining shipped states: step1/step2, library loaded, empty-deck, subdeck list, create-deck dialog — measured in B) | — | <3% |

## Child B — retro coverage (in progress)

Comparison methodology (frozen with the first enforcing test):
per-pixel diff on the physical 2× grid with per-channel tolerance 24
**plus ±1 logical px spatial slack** (pixelmatch-style: a pixel counts
as differing only when nothing within a 2-physical-px radius of the
kit shot matches it). The slack absorbs the cross-engine glyph-advance
drift between the kit's browser rasterizer and Flutter (~3% wider
advances at 15px; measured, not fixable from Flutter), while wrong
colors and layout offsets of ≥2 logical px stay fully visible —
`library--empty` still measures 9.33% under this metric, so the gate
retains its sensitivity to real divergence.

Fixes that came out of the first screen (system-wide, kit-correct):

- `AppTextStyles.display/headline` now carry the kit's tight tracking
  (`type-scale.html`: −0.02em on both hero roles).
- `MxText` gained a `lineHeight` token param (`MxLineHeight`) mapped
  through `AppTextStyles.lineHeight*` accessors.
- The parity harness loads the Material Symbols **Rounded** font — the
  kit renders icons with `material-symbols-rounded` (`MxButton.jsx`),
  so kit-parity screens use `*_rounded` icon variants.
- Landing body copy uses the kit's curly apostrophe (`you’re`).

| Screen state | Status | Diff |
| --- | --- | --- |
| `create-deck-firstrun--landing--light` | **Enforced** (`first_run_landing_parity_test.dart`) | 1.28% |
| `create-deck-firstrun--landing--dark` | **Enforced** | <3% (asserted) |
| `library--empty--light` | probe | 9.33% |
| remaining shipped states | pending | — |

Known divergence (documented, within threshold): the landing import
CTA renders disabled until the first-run import flow ships (WBS 8.x);
the kit shot shows it enabled.

- **Process rule live from this merge**: every future PR that adds or
  changes a screen must include its parity comparison and pass <3%
  (or land the fix in the same PR). Recorded in the WBS §6.2 note and
  the loop checklist.

## Acceptance and test procedure

`AC-WBS-3.15-01`: the harness compares any screen state against its
kit shot deterministically; the rule is enforced pre-merge; child B
brings all shipped states under 3% with enforcing tests.

`TEST-WBS-3.15-01`: the parity suites in every gate.

## Failure and completion

- Child B iterates screen-by-screen: fix styling → ratio <3% → probe
  becomes an enforcing assertion. 3.15 flips Done when every shipped
  state enforces.
