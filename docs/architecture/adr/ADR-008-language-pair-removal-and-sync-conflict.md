# ADR-008 — Language-pair removal safety and sync-conflict resolution

- Status: **Accepted**
- Owner: Product
- Accepted: 2026-07-18
- Decision gate: DG-08 (resolves audit conflicts CF-01 and CF-03)

## Context

The comprehensive documentation audit
([`../../audits/documentation-audit-comprehensive-2026-07-18.md`](../../audits/documentation-audit-comprehensive-2026-07-18.md))
recorded two Business↔Design conflicts on data-loss-grade behavior:

- **CF-01** — Removing a Language Pair: business
  ([`../../business/language-pair/remove-language-pair.md`](../../business/language-pair/remove-language-pair.md))
  forbids cascade delete and blocks removal while dependent Decks exist, but the
  design mock (`RemoveLanguageDialog.jsx`) confirmed an immediate cascade delete of
  "all decks and cards for this pair".
- **CF-03** — Sync conflict: business
  ([`../../business/account/resolve-sync-conflict.md`](../../business/account/resolve-sync-conflict.md))
  forbids any default cloud-wins/auto-merge and requires explicit whole-record
  resolution, but the design mock (`SyncBlock.jsx`) showed an automatic
  last-write-wins "Merged safely" state.

## Decision

**Business stands for both.** The business contracts are authoritative; the design
mocks are the losing side and are reconciled to match.

1. **Language-pair removal is never a cascade delete.** A Pair with one or more
   dependent Decks cannot be removed directly — the UI must present a
   *dependency-blocked* state that reports the dependent-Deck count and routes the
   user to manage/move those Decks first. Only a Pair with zero dependent Decks may
   be removed, via a destructive confirmation whose copy must not claim any Deck or
   Card is deleted. No orphan Deck may be produced.

2. **Sync conflicts require explicit resolution.** There is no default cloud-wins
   and no silent last-write-wins merge. A conflict surfaces as an unresolved state
   that pauses the affected sync scope and routes the user to the Compare/decision
   flow (`resolve-sync-conflict.md`); resolution is applied atomically only after an
   explicit user decision. Auto-merge is limited to the object types the
   [DATA-MERGE-v1](../../decision-tables/backup-sync-integrity.md) contract allows.

## Consequences

- Design reconciliation applied in this decision:
  - `RemoveLanguageDialog.jsx` — destructive confirm copy no longer claims Decks/Cards
    are deleted; a new blocked dialog is added for the dependency case.
  - `Languages.jsx` — adds a `remove-blocked` state; the destructive `remove` state is
    the zero-dependency path only.
  - `SyncBlock.jsx` — the `conflict` state now shows an unresolved conflict with a
    "Review changes" action, not an auto-merged success.
  - The `languages` and `account-sync` screen specs' state matrices are updated to match.
- The winning business documents are unchanged in substance; each now links back to
  this ADR for traceability.

## Verification

- No removal path can produce an orphan Deck or cascade-delete Deck/Card
  (`remove-language-pair.md` §6 acceptance).
- No sync path applies a resolution without an explicit user decision
  (`resolve-sync-conflict.md` §6 acceptance); stale versions are revalidated before apply.
- Decision coverage for merge eligibility lives in
  [`../../decision-tables/backup-sync-integrity.md`](../../decision-tables/backup-sync-integrity.md).
