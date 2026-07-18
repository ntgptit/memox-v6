# Work-item metadata schema

- Status: **Current**
- Owner: Delivery / QA

Every WBS work package resolves the following fields in this deterministic
order: WBS row → item-specific register override → longest matching prefix
default. The first defined value wins. Prefix defaults may resolve
`owner`, `domain`, `guard`, `decision_gate` and initial `status`; an item must
override any field whose actual value differs.

| Field | Rule |
| --- | --- |
| `id` | Unique WBS ID; never reused after release |
| `owner` | Accountable team/role, not merely the affected domain |
| `domain` | Owning aggregate, capability, or foundation |
| `inputs` | Accepted ADRs, owning business docs, design specs/KIT gates, upstream outputs |
| `output` | The WBS completion-boundary prose |
| `dependencies` | Only unique WBS IDs or declared milestone IDs; no free text |
| `size` | S/M/L/XL relative estimate; XL must have independently reviewable child evidence |
| `acceptance_id` | Default `AC-WBS-<id>-01`; it names the row completion boundary |
| `test_id` | Default `TEST-WBS-<id>-01`; required even when the result is a docs/contract test |
| `guard` | Applicable verifier/guard profile and explicit exceptions |
| `decision_gate` | Accepted ADR/decision IDs or `none` |
| `status` | Blocked, Ready, In progress, Done |
| `evidence` | Test/report/ADR/trace path; mandatory for Done |
| `implementation_packet` | Exact packet under `docs/wbs/implementation-packets/`; required for implementation items in Ready/In progress/Done |

## Acceptance and test inheritance

- `AC-WBS-<id>-01` means every clause in the row's completion boundary is true.
- `TEST-WBS-<id>-01` proves that AC using the strongest applicable layer from the
  WBS test matrix. A documentation/ADR item uses link, schema, graph, or decision
  validation rather than inventing runtime tests.
- A branch-heavy business item also links its stable decision-table row IDs and
  row-to-test mappings.
- All items inherit FD-01 through FD-16 and the global Definition of Done unless
  the WBS explicitly marks a docs-only activity as not applicable.

## Ready and Done

Ready requires accepted decisions, resolved sources, no open business/design P0,
resolvable dependencies, owner assignment, fixtures/test approach, and no
unapproved guard exception. Done requires acceptance/test IDs, evidence links,
the consolidated verifier marker, traceability update, and zero relevant P0/P1.

- Prefix status `Blocked` is the safe default; dependency completion alone never
  promotes an item automatically.
- `Ready` requires item-specific exact inputs and test/fixture evidence; a broad
  glob inherited from a prefix is insufficient.
- `Ready` implementation items also require an exact implementation packet;
  documentation/governance-only items may use `not applicable` with reason.
- `Done` always requires an item-specific register row with durable evidence.
  Prefix defaults can never make a work item Done.
- Status changes are reviewable register edits; no prose outside this register
  silently changes delivery status.
