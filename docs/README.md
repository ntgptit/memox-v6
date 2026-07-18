# MemoX v6 documentation portal

This index is the entry point for project contracts. A document listed as
canonical owns the decision in its scope; downstream documents link to it and
must not redefine it.

## Canonical sources

| Area | Canonical entry | Owner | Status |
| --- | --- | --- | --- |
| Product and domain | [`business/README.md`](./business/README.md) | Product | Current; feature implementation must reconcile it with design |
| Accepted architecture decisions | [`architecture/README.md`](./architecture/README.md) | Architecture | Accepted baseline, 2026-07-18 |
| Visual values and frozen `Mx*` names | [`design/MemoX Design System_v4/readme.md`](./design/MemoX%20Design%20System_v4/readme.md) | Design System | Current reference kit; accepted ADRs define the Flutter production mapping |
| Design acceptance gates | [`design/mobile-design-kit-audit-v5/README.md`](./design/mobile-design-kit-audit-v5/README.md) | Design System / Accessibility | Current checklist |
| Database and migrations | [`database/README.md`](./database/README.md) | Data | Accepted baseline |
| Delivery plan | [`wbs/memox-v6-development-wbs.md`](./wbs/memox-v6-development-wbs.md) | Delivery | Baseline with accepted decisions |
| Ready execution packets | [`wbs/implementation-packets/README.md`](./wbs/implementation-packets/README.md) | Delivery / QA | Current; WBS 1.1 Ready |
| Traceability and work-item metadata | [`traceability/README.md`](./traceability/README.md) | Delivery / QA | Current |
| Code guard | [`code-verification-guard.md`](./code-verification-guard.md) | Platform / Guard | Current enforced contract |

Cross-cutting supporting contracts:

- [`business/validation-and-normalization-catalog.md`](./business/validation-and-normalization-catalog.md)
- [`architecture/tier1-resource-budgets.md`](./architecture/tier1-resource-budgets.md)
- [`business/account/cloud-service-gate.md`](./business/account/cloud-service-gate.md)
- [`audits/documentation-remediation-2026-07-18.md`](./audits/documentation-remediation-2026-07-18.md)
- [`audits/documentation-coverage-2026-07-19.md`](./audits/documentation-coverage-2026-07-19.md)

## Stop rule

An accepted ADR records the Product Owner decision, but it does not silently
rewrite older business or design prose. If an owning business or design document
still contradicts an ADR, implementation of that affected feature remains
blocked until the owning document is reconciled and linked back to the ADR.

## Delivery entry

Before a work item becomes Ready, apply the Definition of Ready in the WBS and
resolve its inherited metadata in the
[`work-item register`](./traceability/work-item-register.md). Completion requires
the repository verifier, test evidence, and documentation closure described by
the work-item schema.
