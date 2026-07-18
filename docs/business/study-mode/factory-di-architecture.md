# Study Mode implementation architecture — non-normative legacy note

## Status

`SUPERSEDED` as a mandatory business contract.

The previous version mandated `enum → interface → abstract base → five concrete classes → factory/DI`. That structure was not derived from a demonstrated repository need or an accepted architecture ADR, and it incorrectly assigned Attempt persistence/checkpoint advancement to Study Mode. It must not be used as an implementation gate.

## Normative boundaries retained

- Study Mode validates interaction and produces typed canonical evidence.
- Study Session owns Attempt persistence, mastery-round/session checkpoint and finalize orchestration.
- Learning Progress owns pure SRS transition/scheduling semantics.
- UI, Riverpod providers and persistence adapters do not redefine mode outcome rules.
- Dependencies are explicit/test-overridable; no mode locates repositories or global mutable state.

The implementation may use functions, strategies, sealed types, classes or a registry consistent with the accepted Flutter architecture. A factory or abstract base is allowed only when the implementation has demonstrated variation/reuse that justifies it; neither is required by Business.

Canonical contracts are [Study Mode README](./README.md), [Map Mode Outcome](./map-mode-outcome.md), [SM-MATCH-v1](../../decision-tables/match-outcomes.md), [SM-FILL-v1](../../decision-tables/fill-answer-normalization.md) and [ST-SESSION-TYPE-v1](../../decision-tables/study-session-types.md).

## Acceptance criteria

- Architecture/WBS does not require a factory, template-method base or one class per mode solely because of this file.
- Contract tests can exercise every decision-table row without Flutter widget or real persistence.
- Study Mode code cannot commit Attempt, scheduling or Session checkpoints directly.
