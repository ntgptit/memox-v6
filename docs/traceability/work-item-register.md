# Work-item register

- Status: **Current baseline**
- Owner: Delivery / QA
- Updated: 2026-07-18

## Prefix defaults

These defaults cover every WBS item. Item-specific rows below override them.

| Prefix | Owner | Domain | Canonical inputs | Default guard/test |
| --- | --- | --- | --- | --- |
| `0.*` | Product + Architecture | Governance/decisions | `docs/architecture/**`, business/design owners | Docs links + decision/graph validation |
| `1.*` | Platform + QA | Bootstrap/tooling | ADR-002, ADR-005, ADR-007, guard docs, Tier-1 resource budgets | Consolidated verifier contract tests |
| `2.*` | Design System + Flutter UI | Theme/responsive | Design System v4 tokens, ADR-002 | Token/theme/responsive tests + design guard |
| `3.*` | Flutter UI + Accessibility | Shared `Mx*` | Frozen component docs, KIT-15..48 | Widget/golden/a11y + design guard |
| `4.*` | Data + Architecture | Persistence/DI | ADR-001, ADR-003, ADR-004, `docs/database/**` | DAO/repository/migration/provider tests |
| `5.1.*` | Language Pair owner | Language Pair | `docs/business/language-pair/**`, language design specs | Domain/repo/provider/widget/E2E |
| `5.2.*` | Deck owner | Deck | ADR-001, `docs/business/deck/**`, Deck/Library design specs | Decision/transaction/widget/E2E |
| `5.3.*` | Flashcard owner | Flashcard | `docs/business/flashcard/**`, editor/list design specs | Domain/repo/provider/widget/E2E |
| `5.4.*` | Learning owner | Learning Progress/SRS | ADR-003, learning-progress specs | Policy/decision/property/transaction tests |
| `5.5.*` | Learning owner | Study Mode | ADR-003, study-mode specs | Shared mode contract suite |
| `5.6.*` | Learning owner | Study Session | ADR-003, session/mode/result specs | Fake-clock/repo/provider/widget/restart E2E |
| `5.7.*` | Today owner + Release QA | Today/first-learning release | All `5.1..5.6` gates, Today specs | Full Tier-1 journey + verifier marker |
| `6.*` | Content owners | Deck/Flashcard/Library | Owning business/design flows | Complete-slice gate |
| `7.*` | Goal/Streak owners | Goal/Streak/Today/Result | Owning business/design flows | Clock/timezone/projection E2E |
| `8.*` | Preferences owner | Preferences | Preferences specs + accepted scope | Provider/widget/persistence tests |
| `9.*` | Reminder owner + Platform | Reminder | Reminder specs + Tier-1 capability matrix | Permission/time/platform E2E |
| `10.*` | Search owner | Search | Search specs | Index/query/navigation E2E |
| `11.*` | Statistics owner | Statistics | Statistics specs + source events | Projection/rebuild/performance tests |
| `12.*` | Audio owner + Platform | Audio Playback | Audio specs + capability matrix | Lifecycle/platform E2E |
| `13.*` | Transfer owner + Security | Content Transfer | Import/export specs | Parser/property/security/rollback tests |
| `14.*` | Account owner + Security | Account/Sync | Account specs + accepted cloud-service gate | Sync chaos/security tests |
| `15.*` | Backup owner + Security | Backup | Backup specs + database migration contract | Disaster/rollback/compatibility tests |
| `16.*` | Release QA | Release hardening | Release-scope milestone and all included wave gates | Full release verifier/certification |

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
| Five modes | `5.5.1–5.5.6` | `business/study-mode/**` | five mode specs | ADR-003/007 | Shared contract suite |
| Session/start/recovery | `5.6.1–5.6.14` | `business/study-session/**` | picker/session/result | ADR-003/005/006/007, schema v1 | Durable attempt + fake-clock/restart E2E |
| Today/release | `5.7.1–5.7.5` | `business/today-dashboard/**` | dashboard | All accepted ADRs | Full Tier-1 first-learning gate |

## Current status rule

Items `0.1–0.6` are Done only after owning business/design documents are actually
reconciled and linked. Accepted ADRs alone set the decision to Accepted; they do
not make contradictory source prose disappear. All implementation items remain
Blocked until their Definition of Ready resolves that check.
