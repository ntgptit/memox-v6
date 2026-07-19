# WBS P0 — Historical Visual Parity Audit packet

| Field | Value |
| --- | --- |
| Status | **Ready** — `P0.1` active (2026-07-19) |
| Owner/domain | Design System / QA / Flutter UI |
| Depends on | `3.12` Done, `3.15` child A Done, `1.6` Done, `1.7` Done |
| Decision gates | Owner directive 2026-07-19: Flutter Web ↔ Design Kit comparison is a merge gate at ≤3%; historical UI is retro-covered before new UI work |
| Acceptance | `AC-WBS-P0-01` … `AC-WBS-P0-06` |
| Test | `TEST-WBS-P0-01` … `TEST-WBS-P0-06` |
| Blocks | every remaining UI work package (`5.3.2+`, `5.6.*`, `5.7.*`, `6.*`–`16.*`) |

## Why this packet exists

The WBS 3.15 harness proves a state's parity *inside* `flutter_test` — it
renders the widget tree through the Flutter test binding and diffs the result.
That is fast and it caught real system-wide defects, but it does not exercise
the artefact users receive: the compiled Flutter Web bundle, the CanvasKit
rasterizer, real font loading, real routing, real gesture handling and real
layout under a browser viewport. Owner directive of 2026-07-19 makes the
browser-rendered comparison the gate.

Consequence, recorded explicitly so it is not rediscovered later: **3.15 and
Phase 0 are two layers of the same rule, not duplicates.** 3.15 stays as the
sub-second pre-push check. Phase 0 is the pre-merge authority. When the two
disagree, Phase 0 wins and the 3.15 tolerance is re-derived from it.

## Canonical inputs

- Owner directive, 2026-07-19 (visual parity merge gate, Phase 0 precedence).
- Owner directive, 2026-07-19 (second): E2E flows follow the **Master flow** in
  `docs/business/**` — the `# 3. Master flow` mermaid chart owned by each
  use-case document (37 documents).
- WBS §6.4 (VP-01–VP-08), §6.5 (merge gate, frozen environment, output
  contract, parity DoD), §6.6 (master-flow conformance), §7 Phase 0 register.
- `docs/business/navigation/README.md` — canonical destinations, first-launch
  guards, Tier-1 Web Back/Forward/refresh/deep-link semantics.
- Kit shot matrix: `docs/design/MemoX Design System_v4/ui_kits/memox-app/shots/`
  — 480 PNGs, `<screen>--<state>--<theme>.png`, 390 logical px at 2×.
- Existing harness and frozen metric: `test/support/kit_parity.dart`,
  `docs/wbs/implementation-packets/WBS-3.15-kit-parity-gate.md`.
- Deterministic ports: `lib/core/{time,ids,random}/**` (1.6),
  `lib/data/dev/dev_fixtures.dart` (1.7).

## In scope

- The 48 `MX-VIS-*` IDs in the WBS Phase 0 register, light and dark.
- A Flutter Web parity harness and its CI wiring.
- Fixture addressing for every registered state.
- Remediation of every measurable state to ≤3%.

## Out of scope

- New product features. Phase 0 changes styling, shared widgets, tokens,
  fixtures and test infrastructure — it does not add screens.
- States whose kit shot depends on unshipped features (`MX-VIS-017`, `020`,
  `021`, `022`, `034`). These are recorded with the unblocking WBS ID and
  measured, but not required to pass before `P0.6`.
- Non-390 viewports as a comparison source.

## Child boundaries

| Child | WBS | Scope |
| --- | --- | --- |
| A | `P0.1` | Census. Freeze the `MX-VIS-*` register; resolve every ID to a kit shot or an explicit *no reference* decision. |
| B | `P0.2` | Harness: web build, server, Playwright project, comparator, artifact writer, verifier step. |
| C | `P0.3` | Fixture layer addressable from the web build. |
| D | `P0.4` | Playwright specs + measured ratio for every ID. |
| E | `P0.5` | Remediation to ≤3%. |
| F | `P0.6` | Exit gate: enforcement, regression protection, merge-gate activation. |

## Exact files

Create:

| Path | Responsibility |
| --- | --- |
| `tool/parity/package.json` | Pinned Playwright + comparator dependencies (first Node manifest in the repo; do not hoist to root). |
| `tool/parity/playwright.config.ts` | Frozen environment: Chromium, `390×780` @ DPR 2, reduced motion, `en`, offline, single worker, retries 0. |
| `tool/parity/build_web.mjs` | `flutter build web` (CanvasKit, no wasm) into a run directory. |
| `tool/parity/serve.mjs` | Static server for the built bundle; no network egress. |
| `tool/parity/compare.mjs` | Pixel diff (2× grid, per-channel tolerance 24, ±1 logical px slack) → ratio + diff PNG. |
| `tool/parity/report.mjs` | Writes the §6.5 output-contract record per state. |
| `tool/parity/flows.ts` | `enterFlow(<business-doc-id>)` — the Master flow entry/guard traversals from `docs/business/navigation/README.md`; the only sanctioned way a spec reaches a starting node. |
| `tool/parity/flow_lint.mjs` | Asserts every spec header names a real `docs/business/**` doc with a `# 3. Master flow`, and flags undeclared `page.goto()` shortcuts. |
| `tool/parity/specs/<screen>.spec.ts` | One spec per screen, one test per `MX-VIS-*` × theme; header binds it to its Master flow node. |
| `lib/app/dev/parity_entrypoint.dart` | Reads `?fixture=<MX-VIS-id>&theme=<light\|dark>`, installs deterministic ports + fixture, mounts the route. Compiled out of release builds by an assert-gated guard, same policy as `dev_fixtures.dart`. |
| `evidence/parity/<MX-VIS-id>--<theme>/{expected,actual,diff}.png` | Durable artifacts. |
| `evidence/parity/summary.json` | Machine-readable results for the gate. |

Modify:

| Path | Change |
| --- | --- |
| `tool/verify/run.mjs` | New `kit visual parity` step; fails on any state over threshold or any unmeasured registered state. |
| `docs/wbs/memox-v6-development-wbs.md` | Already updated (§6.4, §6.5, §7 Phase 0). |
| `docs/traceability/work-item-register.md` | `P0.*` prefix row + item rows. |
| `.gitignore` | Ignore the web build output directory, not the evidence directory. |

Do not edit: generated Drift/Riverpod output, `lib/l10n/generated/**`, kit shots.

## Fixture contract (`P0.3`)

- One fixture per `MX-VIS-*` ID, keyed by that ID.
- A fixture sets: database contents, active language pair, draft state, provider
  overrides, injected clock instant, ID sequence, random seed, and the initial
  route.
- A fixture never reaches the network and never reads a real clock.
- A state that needs a user action to reach (dialog open, field focused,
  submitting, keyboard visible) is produced by the Playwright flow, not by a
  fixture that fakes the rendered result. Faking the end state hides exactly the
  defects this gate exists to catch.
- **A fixture sets data preconditions only — never flow position.** The fixture
  may seed "one deck with five cards exists"; it may not seed "the user is on
  the Card Editor". Flow position comes from traversing the Master flow.
- The `submitting` states pin an in-flight command with a completer the fixture
  never completes, so the capture is stable.

## Master-flow conformance (`P0.4`)

Each spec file carries a header block binding it to the business source:

```ts
// MX-VIS-025 · Create Deck dialog · root default
// Master flow: docs/business/deck/create-deck.md §3
// Path: App launch → Dashboard/Library → "Create Deck dialog"
```

- `tool/parity/specs/**` traverses from the Master flow entry node. Helper
  `enterFlow('deck/create-deck')` performs the launch + guard sequence from
  `docs/business/navigation/README.md`; it does not `page.goto()` a deep route.
- Reaching a state by `page.goto('/deck/<id>')` is allowed **only** for states
  whose Master flow entry genuinely is a deep link (notification entry, Web
  refresh, restored URL) and the spec says so.
- Branch coverage is asserted, not assumed: `P0.1` records, per business
  document, which chart nodes have a covering `MX-VIS-*` and which do not.
- Web-specific Tier-1 behaviour on the traversed path — browser Back/Forward,
  refresh mid-flow, deep-link recovery — is exercised at least once per screen
  group, since these only exist on the Flutter Web target and the in-test 3.15
  harness cannot see them at all.
- A divergence between the chart and the implemented navigation stops the item
  (FD-01 / DoR 3). It is recorded as a business↔implementation conflict, never
  patched by rewriting the spec to match the code.

## State/action matrix

Per registered ID the spec asserts, before capture:

| Check | Failure meaning |
| --- | --- |
| Master flow node reached by traversal | The spec shortcut the path; the evidence is void. |
| Route resolved | The state is unreachable — a routing defect, not a styling one. |
| Flow steps completed | The user cannot reach the state. |
| Scroll position matches the register | Non-deterministic capture. |
| No overflow/clip in the render tree | Layout defect, blocks PASS regardless of ratio. |
| Every interactive element hit-testable | Obscured control, blocks PASS regardless of ratio. |
| Fonts loaded, one settled frame | Flaky diff. |
| Three consecutive identical captures | Unstable state; the ID is not gate-ready. |

## Acceptance

- `AC-WBS-P0-01` — the register enumerates every implemented screen, dialog,
  sheet and state; each ID resolves to a kit shot or a recorded *no reference*
  decision with an owner, **and to its owning Master flow node**; uncovered
  chart branches are listed as gaps.
- `AC-WBS-P0-02` — the harness produces, for any registered ID, a ratio plus
  `expected`/`actual`/`diff` artifacts from a real Flutter Web build driven by
  Playwright, reproducibly across three runs.
- `AC-WBS-P0-03` — every registered ID has a fixture that reproduces its kit
  state deterministically.
- `AC-WBS-P0-04` — every registered ID has a Playwright flow that traverses its
  owning Master flow from the entry node and a measured ratio in `summary.json`;
  no ID is unmeasured and no ID reaches its state by an undeclared deep link.
- `AC-WBS-P0-05` — every measurable ID is ≤3% in both themes, or carries an
  approved, expiring exception naming the blocking WBS item.
- `AC-WBS-P0-06` — the verifier fails on regression; the merge gate is active;
  new UI work is unblocked.

## Tests

- `TEST-WBS-P0-02` — harness self-test: a deliberately shifted render is
  detected; an identical render reports ~0%.
- `TEST-WBS-P0-03` — fixture determinism: same ID → byte-identical DB state and
  clock across runs.
- `TEST-WBS-P0-04` — per-ID Playwright specs, each declaring its Master flow
  document and node.
- `TEST-WBS-P0-04b` — flow-conformance lint: every spec header resolves to an
  existing `docs/business/**` document with a `# 3. Master flow` section, and any
  `page.goto()` outside `enterFlow` carries a declared deep-link justification.
- `TEST-WBS-P0-06` — verifier integration: an injected >3% regression fails the
  build.

## Verifier command

```bash
node tool/verify/run.mjs --full
node tool/parity/run.mjs --id MX-VIS-018    # single state, inner loop
```

## Completion procedure

1. Close children in order A→F; each updates its register row with the measured
   evidence, never with a claim.
2. `P0.5` records, for every remaining divergence, the concrete cause — not
   "minor rendering difference".
3. `P0.6` flips the register rows to Done, activates the merge gate, and
   unblocks the halted UI rows.
4. WBS 3.15 child B is re-scoped at `P0.6`: its enforced states become the fast
   pre-push layer over the Phase 0 register rather than a parallel gate.
