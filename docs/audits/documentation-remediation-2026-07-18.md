# MemoX v6 documentation remediation — 2026-07-18

## Verdict

**Documentation contract: APPROVED WITH CHANGES APPLIED.** Foundation and the first-learning
vertical slice may enter implementation. Design release certification remains **BLOCKED** until
the Flutter implementation produces the Tier-1 Web/Android visual, accessibility, localization and
adaptive runtime evidence tracked by the Design Kit issue register.

This distinction is intentional: missing runtime evidence is not repaired by inventing screenshots
inside a documentation task.

## Accepted Product defaults

| Decision | Accepted contract |
| --- | --- |
| Platform | Flutter multi-platform; Web + Android Tier 1; iOS/Windows/macOS/Linux roadmap |
| Deck | Exclusive Empty/Leaf/Parent; no mixed content or direct Leaf↔Parent conversion |
| Sessions | `newLearning`, `dueReview`, `relearn`, `practice`; New Learning owns the five ordered stages |
| Start | Mode selection is separate from explicit `Start session` |
| Guess | At least five distinct normalized meanings |
| Recall | Deterministic 20-second active-time timeout |
| SRS | Read-only `leitner-8-box-v1`; Box 0 pre-SRS, Box 1–7 intervals, Box 8 mastered |
| Locale | English/Vietnamese v1; RTL-ready, runtime RTL deferred |
| Persistence | Shared Drift schema with separate Web/Android openers and migration tests |
| Cloud | Local-only v1 default; provider/security/retention gate required before cloud implementation |

The accepted records are indexed by [`../architecture/README.md`](../architecture/README.md) and
the Product register in [`../business/README.md`](../business/README.md).

## Remediation closure

| Area | Main correction | Evidence | Status |
| --- | --- | --- | --- |
| Source of truth | Added documentation portal, accepted ADRs and stop rule | [`../README.md`](../README.md) | Closed |
| Business/design conflicts | Reconciled Deck, picker/start, Guess threshold, Recall timeout, read-only SRS and Today recovery states | Business catalog; Design `SCOPE.md`; affected specs/source | Closed contractually |
| SRS safety | Exhaustive transition table, UTC/due semantics, sticky-wrong, terminal-once/idempotency/transaction/migration | [`../decision-tables/srs-8-box-v1.md`](../decision-tables/srs-8-box-v1.md) | Closed |
| Session safety | Distinct session types, content-change table and durable attempt ordering | [`../decision-tables/study-session-types.md`](../decision-tables/study-session-types.md) | Closed |
| Validation gaps | Cross-object validation catalog, Card Detail and Tags ownership | [`../business/validation-and-normalization-catalog.md`](../business/validation-and-normalization-catalog.md) | Closed |
| Cloud ambiguity | Explicit local-only v1 and fail-closed provider decision gate | [`../business/account/cloud-service-gate.md`](../business/account/cloud-service-gate.md) | Closed for v1; later decision-gated |
| Architecture/Riverpod | Dependency direction, provider lifecycle, deterministic clock/IDs/random, typed failures and test overrides | [`../architecture/adr/ADR-007-riverpod-and-testing.md`](../architecture/adr/ADR-007-riverpod-and-testing.md) | Closed |
| Data | Shared schema, platform openers, migration/rollback/idempotency contract | [`../database/README.md`](../database/README.md) | Closed |
| Resource limits | Repeatable Small/Standard/Large profiles and measurable Tier-1 budgets | [`../architecture/tier1-resource-budgets.md`](../architecture/tier1-resource-budgets.md) | Closed |
| Traceability | Work-item schema and first-learning chain Business→Design→Architecture→WBS→Test | [`../traceability/work-item-register.md`](../traceability/work-item-register.md) | Closed |
| WBS | Unique dependency graph, corrected critical path and release ancestors | [`../wbs/memox-v6-development-wbs.md`](../wbs/memox-v6-development-wbs.md) | Closed |
| Guard | Correct package namespace, canonical SRS path and strict CI profile regression tests | [`../code-verification-guard.md`](../code-verification-guard.md) | Closed contractually |
| Verification | One entry for hooks/CI/local checks; dependency versions pinned | [`../../tool/verify/run.mjs`](../../tool/verify/run.mjs) | Closed |

## Current Design Kit gate

The structural Design Kit validation passes, but the current release status is correctly red:

- 48/48 KIT groups reviewed: 37 PASS, 11 PARTIAL, 0 unreviewed/BLOCKED groups.
- Issue register: 105 FIXED, 4 ACCEPTED, 10 PARTIAL and 3 OPEN.
- Gate-impacting remainder: 0 P0 and 13 P1.

The 13 P1 items require runtime evidence from the future Flutter Web/Android build: width boundaries,
Android tablet/landscape/IME/Back, Web keyboard/pointer, en/vi ARB parity at 200% text, changed study
states and current accessibility evidence. They are listed in
[`../design/mobile-design-kit-audit-v5/issue-register.md`](../design/mobile-design-kit-audit-v5/issue-register.md)
and are ancestors of the first-learning release gate, not blockers to starting foundation work.

## Verification record

| Check | Result |
| --- | --- |
| Local Markdown/HTML links | Pass; 341 files scanned, 0 broken |
| WBS IDs | 151 unique IDs; 0 duplicate, unresolved dependency or cycle |
| Decision rows | 77 unique rows |
| Design checklist validator | Pass; 48 files, 288 items, no broken link/duplicate/near duplicate/invalid slug |
| Guard ruleset contract tests | Pass; 8 tests in the canonical verifier |
| Guard naming/alignment targeted suite | Pass; 13 tests |
| Guard local profile | Pass with expected scaffold warnings; no source implementation exists for most configured future paths |

The canonical command is `node tool/verify/run.mjs`. Its full mode additionally runs dependency
resolution, localization generation, code generation, formatting, analysis and Flutter tests.

## Readiness

| Dimension | Status | Boundary |
| --- | --- | --- |
| Business | Ready | Cloud capabilities remain explicitly deferred/gated |
| Design contract | Ready to implement | Release evidence/sign-off remains blocked until runtime proof exists |
| Architecture | Ready | Implement only the documented boundaries; no extra factory layer |
| Riverpod | Ready | Annotation/generator and deterministic override contract accepted |
| Guard | Ready for foundation | Missing-target warnings retire as WBS creates the canonical paths; CI is strict |
| Test strategy | Ready | Decision/property/repository/provider/widget/E2E layers are traced |
| WBS | Ready | First-learning critical path is explicit and acyclic |
| Start-learning flow | Ready to implement | Cannot pass release gate until Tier-1 runtime evidence is attached |
| SRS | Ready to implement | Canonical pure-domain Dart path does not exist yet by design |

## Fastest safe implementation order

1. Canonical verifier/dependency/bootstrap/test infrastructure.
2. Design token mapping → Theme → adaptive Web/Android shell → minimal shared `Mx*` widgets.
3. Drift schema/openers/migrations → repository ports → deterministic Clock/ID providers.
4. Language Pair → exclusive Deck → five valid Flashcards.
5. Learning Progress/SRS policy and durable attempt transaction.
6. Mode Picker + explicit Start → five New Learning stages → resume/finalize.
7. Today projection and complete first-learning E2E.
8. Attach Web/Android visual/a11y/l10n evidence and close all 13 Design P1 gates.
9. Continue content management, goal/streak/statistics and conditional capabilities by WBS.
