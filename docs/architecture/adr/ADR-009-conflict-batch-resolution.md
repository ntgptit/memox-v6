# ADR-009 — Batch resolution of the remaining audit conflicts (CF-02, CF-04…CF-17)

- Status: **Accepted**
- Owner: Product
- Accepted: 2026-07-18
- Decision gate: DG-09 (resolves the remaining conflicts in the
  [comprehensive documentation audit](../../audits/documentation-audit-comprehensive-2026-07-18.md) §E,
  after CF-01/CF-03 in [ADR-008](./ADR-008-language-pair-removal-and-sync-conflict.md))

## Context

The audit's conflict register listed 17 Business↔Design (and one Business↔Business, one
design-internal) decisions. CF-01 and CF-03 were decided in ADR-008. This ADR records the
Product Owner's decision on the remainder, so the design kit can be reconciled to a single
source of truth.

## Decision

**Default rule: business stands.** Per `AGENTS.md`, `docs/business/**` is the source of truth
for domain behavior; where a design mock diverged, the mock is reconciled to business. Scope is
not narrowed to the mock's simplification. Specifics:

| # | Decision |
| --- | --- |
| CF-02 | **Account/cloud is deferred.** No provider (Google / email-password) is committed; cloud CTAs are disabled/"coming soon" until `cloud-service-gate.md` is accepted. App stays fully local-first. |
| CF-04 | **Edit Deck is a full form** (name + optional description + read-only language pair); the same form serves rename and metadata edit. |
| CF-05 | **Card audio owns Generate / Attach file / Remove** as first-class actions with their state matrix. |
| CF-06 | **Additional translations are an ordered, reorderable, multi-item list** with stable identity. |
| CF-07 | **Duplicate resolution is a 4-way decision** (Edit / Open existing / Keep both / Merge) with a side-by-side compare. |
| CF-08 | **Import duplicate handling is per-item/bulk Skip / Merge / Import-anyway** with incoming-vs-existing compare and a created/merged/skipped commit breakdown. |
| CF-09 | **The four graded modes keep the unlimited mastery-round loop** — `round-complete` and `retry-round` (and Guess `invalid-distractor-pool`) are canonical states. |
| CF-10 | **Export shows deck scope/Change + a pre-export Summary; content export never carries Learning Progress** (the "Include review state" toggle is removed — progress lives in Backup, not content transfer). |
| CF-11 | **Transfer formats are exactly memox-csv-v1 + memox-json-v1** (JSON preserves hierarchy). Excel/clipboard are out of scope. |
| CF-12 | **"Mode settings" is Configure Mode Preferences** — enable/disable/reorder modes and pick a default. No "words per round" (a graded round is all valid cards) and no shuffle toggle (order randomization is always deterministic). |
| CF-13 | **No Example field and no "keep adding" mode** — the Card is term/meaning/translations/tags/audio, and a successful Save closes the editor. |
| CF-14 | **Search filters by object type / language pair / deck scope / visibility** — not SRS status; Search does not index Learning Progress. |
| CF-15 | **Reset-progress uses the business copy** — "Keep progress" / "Reset progress", affected-count, and the nested-decks-stay reassurance. |
| CF-16 | **First launch is soft-onboarding** (Business↔Business): a no-content user may choose "Not now" and land on an empty Today; the Language-Pair prerequisite guards content creation, not reaching Today. |
| CF-17 | **Design-kit scope split** (design-internal): Web-expanded/responsive layout and hardware-keyboard support are **in** Tier-1 scope (Web); Android tablet/landscape/orientation are **out** for v1 (roadmap). `issue-register.md` and the KIT Evidence Logs are reconciled to this split (Web items stay tracked/open; Android-orientation items become ACCEPTED per `SCOPE.md`). |

## Consequences

- Design reconciliation applied now (copy/behavior/state/contract level):
  account-sync (CF-02), deck-settings Edit form (CF-04), export scope/summary + format set
  (CF-10/CF-11), import sources + duplicate entry point (CF-08/CF-11), settings mode preferences
  (CF-12), flashcard editor (CF-13 removal; CF-05/06/07 contract notes + spec matrices), search
  filters (CF-14), reset dialog (CF-15), the four graded-mode spec matrices (CF-09), and the
  first-launch guard prose (CF-16).
- **Follow-on implementation work** (net-new interaction surfaces, recorded as pending in the
  affected screen specs, not silently dropped): the audio Attach/Remove surface (CF-05), the
  ordered multi-translation list (CF-06), the duplicate compare/merge screen (CF-07), the import
  per-item resolution list (CF-08), and the graded-mode `round-complete`/`retry-round`
  (+ `invalid-distractor-pool`) screens (CF-09).
- **CF-17** per-row status reclassification in `issue-register.md`/KIT Evidence Logs is mechanical
  follow-through for the Design System owner against the split recorded above.

## Verification

- Winning business contracts are unchanged in substance; reconciled design docs reference this ADR.
- The audit conflict register (§E) and its machine-readable findings appendix mark CF-02…CF-17 resolved.
- `node tool/verify/run.mjs` (docs + guard + analyze/test) remains green.
