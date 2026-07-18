# Work-item register

- Status: **Current baseline**
- Owner: Delivery / QA
- Updated: 2026-07-19

## Prefix defaults

These defaults cover every WBS item. Item-specific rows below override them.

| Prefix | Owner | Domain | Canonical inputs | Default guard/test | Decision gate | Default status |
| --- | --- | --- | --- | --- | --- | --- |
| `0.*` | Product + Architecture | Governance/decisions | `docs/architecture/**`, business/design owners | Docs links + decision/graph validation | Item override | Blocked |
| `1.*` | Platform + QA | Bootstrap/tooling | ADR-002, ADR-005, ADR-007, guard docs, Tier-1 resource budgets | Consolidated verifier contract tests | DG-02 | Blocked |
| `2.*` | Design System + Flutter UI | Theme/responsive | Design System v4 tokens, ADR-002 | Token/theme/responsive tests + design guard | DG-02, DG-05 | Blocked |
| `3.*` | Flutter UI + Accessibility | Shared `Mx*` | Frozen component docs, KIT-15..48 | Widget/golden/a11y + design guard | DG-02, DG-05 | Blocked |
| `4.*` | Data + Architecture | Persistence/DI | ADR-001, ADR-003, ADR-004, `docs/database/**` | DAO/repository/migration/provider tests | DG-01, DG-03, DG-06 | Blocked |
| `5.1.*` | Language Pair owner | Language Pair | `docs/business/language-pair/**`, language design specs | Domain/repo/provider/widget/E2E | DG-02, DG-05 | Blocked |
| `5.2.*` | Deck owner | Deck | ADR-001, `docs/business/deck/**`, Deck/Library design specs | Decision/transaction/widget/E2E | DG-01 | Blocked |
| `5.3.*` | Flashcard owner | Flashcard | `docs/business/flashcard/**`, editor/list design specs | Domain/repo/provider/widget/E2E | DG-01 | Blocked |
| `5.4.*` | Learning owner | Learning Progress/SRS | ADR-003, learning-progress specs | Policy/decision/property/transaction tests | DG-03, DG-04 | Blocked |
| `5.5.*` | Learning owner | Study Mode | ADR-003, study-mode specs | Shared mode/factory contract suite | DG-03 | Blocked |
| `5.6.*` | Learning owner | Study Session | ADR-003, session/mode/result specs | Fake-clock/repo/provider/widget/restart E2E | DG-03 | Blocked |
| `5.7.*` | Today owner + Release QA | Today/first-learning release | All `5.1..5.6` gates, Today specs | Full Tier-1 journey + verifier marker | DG-01..DG-06 | Blocked |
| `6.*` | Content owners | Deck/Flashcard/Library | Owning business/design flows | Complete-slice gate | DG-01 | Blocked |
| `7.*` | Goal/Streak owners | Goal/Streak/Today/Result | Owning business/design flows | Clock/timezone/projection E2E | DG-02 | Blocked |
| `8.*` | Preferences owner | Preferences | Preferences specs + accepted scope | Provider/widget/persistence tests | DG-02 | Blocked |
| `9.*` | Reminder owner + Platform | Reminder | Reminder specs + Tier-1 capability matrix | Permission/time/platform E2E | DG-02 | Blocked |
| `10.*` | Search owner | Search | Search specs | Index/query/navigation E2E | DG-02 | Blocked |
| `11.*` | Statistics owner | Statistics | Statistics specs + source events | Projection/rebuild/performance tests | DG-03 | Blocked |
| `12.*` | Audio owner + Platform | Audio Playback | Audio specs + capability matrix | Lifecycle/platform E2E | DG-02 | Blocked |
| `13.*` | Transfer owner + Security | Content Transfer | Import/export specs | Parser/property/security/rollback tests | DG-06 | Blocked |
| `14.*` | Account owner + Security | Account/Sync | Account specs + accepted cloud-service gate | Sync chaos/security tests | DG-02, DG-06 | Blocked |
| `15.*` | Backup owner + Security | Backup | Backup specs + database migration contract | Disaster/rollback/compatibility tests | DG-06 | Blocked |
| `16.*` | Release QA | Release hardening | Release-scope milestone and all included wave gates | Full release verifier/certification | DG-01..DG-06 | Blocked |

## Item-specific overrides and evidence

Only rows below override the inherited status. `AC-WBS-*` and `TEST-WBS-*`
expand according to [the schema](./work-item-schema.md); Done evidence is durable
and item-specific, while Ready rows link exact execution packets.

| WBS | Status | Decision gate | Exact inputs | Acceptance/test | Packet | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `0.1` | Done | DG-01 | ADR-001, Deck business/design owners, mixed-content rows | `AC-WBS-0.1-01`; `TEST-WBS-0.1-01` | Not applicable — governance | `docs/architecture/adr/ADR-001-deck-content-model.md`; `docs/decision-tables/deck-mixed-content.md` |
| `0.2` | Done | DG-02, DG-05 | ADR-002, platform/localization matrices | `AC-WBS-0.2-01`; `TEST-WBS-0.2-01` | Not applicable — governance | `docs/architecture/adr/ADR-002-platform-and-adaptive-scope.md`; `docs/design/MemoX Design System_v4/SCOPE.md` |
| `0.3` | Done | DG-03, DG-04 | ADR-003, SRS policy, SRS8-001..028 | `AC-WBS-0.3-01`; `TEST-WBS-0.3-01` | Not applicable — governance | `docs/business/learning-progress/srs-8-box-policy.md`; `docs/decision-tables/srs-8-box-v1.md` |
| `0.4` | Done | DG-01, DG-04 | Guard memox ruleset and architecture paths | `AC-WBS-0.4-01`; `TEST-WBS-0.4-01` | Not applicable — governance | `docs/code-verification-guard.md`; guard regression suite in the consolidated verifier |
| `0.5` | Done | DG-01..DG-06 | Architecture, decisions, business, database, traceability | `AC-WBS-0.5-01`; `TEST-WBS-0.5-01` | Not applicable — governance | `docs/README.md`; docs inventory/link/traceability checks in the consolidated verifier |
| `0.6` | Done | DG-02, DG-05 | ADR-002 and release scope/exclusions | `AC-WBS-0.6-01`; `TEST-WBS-0.6-01` | Not applicable — governance | `docs/architecture/adr/ADR-002-platform-and-adaptive-scope.md`; `docs/design/MemoX Design System_v4/SCOPE.md` |
| `1.1` | **Ready** | DG-02, DG-05, DG-06 | Current pubspec/lock, ADR-002/004/005/006/007, database and guard contracts | `AC-WBS-1.1-01`; `TEST-WBS-1.1-01` | `docs/wbs/implementation-packets/WBS-1.1-dependency-baseline.md` | Pending; mandatory before Done |
| `1.2` | Done | DG-02 | Verifier, hooks, CI and guard tests | `AC-WBS-1.2-01`; `TEST-WBS-1.2-01` | Not applicable — tooling already implemented | `tool/verify/run.mjs`; pass marker `.dart_tool/memox_verify_pass.json` emitted by the full gate |

## Accepted decision gates

| Gate | ADR | Status | Owner/date |
| --- | --- | --- | --- |
| DG-01 | ADR-001 | Accepted | Product Owner, 2026-07-18 |
| DG-02 | ADR-002 | Accepted | Product Owner, 2026-07-18 |
| DG-03 | ADR-003 | Accepted | Product Owner, 2026-07-18 |
| DG-04 | ADR-003 plus frozen canonical SRS path | Accepted | Architecture, 2026-07-18 |
| DG-05 | ADR-002 | Accepted | Product Owner, 2026-07-18 |
| DG-06 | ADR-004 | Accepted | Product Owner, 2026-07-18 |

## First-learning trace

| Capability/output | WBS | Business source | Design source | Architecture/data | Acceptance/test |
| --- | --- | --- | --- | --- | --- |
| Foundation ready | `0.5`, `1.1–1.11`, `2.1–2.10`, `4.1–4.10` | Cross-cutting | Tokens/KIT foundation | ADR-002/004/005/007, DB contract | Derived AC/TEST IDs + verifier |
| Minimal shared UI | `3.1–3.10`, `3.12` | Interaction inputs | Frozen `Mx*`, session/editor/picker specs | ADR-002/006/007 | Widget/golden/a11y |
| Language Pair | `5.1.1–5.1.3` | `business/language-pair/**` | `languages`, first-run | ADR-006/007, schema v1 | Domain through E2E |
| Deck | `5.2.1–5.2.6` | `business/deck/**` | Library/create/empty Deck | ADR-001, schema v1 | Decision + transaction + E2E |
| Flashcards | `5.3.1–5.3.4` | `business/flashcard/**` | editor/list | ADR-001/007, schema v1 | Rollback/idempotency/E2E |
| Progress/SRS | `5.4.1–5.4.5` | `business/learning-progress/**` | settings/session/result states | ADR-003, canonical domain policy path | SRS rows/property/time tests |
| Six strategies | `5.5.1–5.5.6` | `business/study-mode/**` | five learning-mode specs + SRS Binary Review | ADR-003/007 + mandatory Factory | Shared factory/strategy contract suite |
| Session/start/recovery | `5.6.1–5.6.14` | `business/study-session/**` | picker/session/result | ADR-003/005/006/007, schema v1 | Durable attempt + fake-clock/restart E2E |
| Today/release | `5.7.1–5.7.5` | `business/today-dashboard/**` | dashboard | All accepted ADRs | Full Tier-1 first-learning gate |

## Current status rule

The item-specific table is authoritative for current Ready/Done status. Every other
item inherits `Blocked` from its longest matching prefix until an explicit Ready
or Done override satisfies the schema. Accepted ADRs alone never promote status,
and contradictory business/design prose must be reconciled before an override.
