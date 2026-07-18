# MemoX v6 architecture decisions

Status: **Accepted baseline**

Accepted by: **Product Owner**

Acceptance date: **2026-07-18**

These ADRs close the initial architecture decision gates. They do not authorize
implementation against an unreconciled business/design conflict; see the
repository stop rule in [`../README.md`](../README.md).

Tier-1 performance and large-data verification use the canonical
[`resource budgets`](./tier1-resource-budgets.md).
Guard alignment and planned-path activation debt are recorded in
[`guard-compatibility.md`](./guard-compatibility.md).

| ADR | Decision | Status |
| --- | --- | --- |
| [ADR-001](./adr/ADR-001-deck-content-model.md) | Deck content is exclusive: cards or child Decks, never both | Accepted |
| [ADR-002](./adr/ADR-002-platform-and-adaptive-scope.md) | Flutter; Tier 1 Web + Android; other platforms roadmap | Accepted |
| [ADR-003](./adr/ADR-003-learning-session-and-scheduling.md) | New-learning five-stage session; separate due/relearn/practice; fixed SRS | Accepted |
| [ADR-004](./adr/ADR-004-local-persistence-platforms.md) | One shared Drift schema with Web and Android openers | Accepted |
| [ADR-005](./adr/ADR-005-bootstrap-and-error-boundary.md) | Small bootstrap, typed failures, redacted observability | Accepted |
| [ADR-006](./adr/ADR-006-navigation-contract.md) | GoRouter constants/wrappers and guarded learning entry | Accepted |
| [ADR-007](./adr/ADR-007-riverpod-and-testing.md) | Riverpod Annotation, provider DI, deterministic test overrides | Accepted |

## Dependency direction

```text
Flutter UI / route
  -> generated Riverpod presentation provider
    -> domain use case
      -> domain repository port
        -> data repository implementation
          -> Drift DAO / platform adapter
```

The repository keeps app-wide `domain` and `data` roots and feature-owned
presentation roots. No additional factory or compatibility layer is implied.
