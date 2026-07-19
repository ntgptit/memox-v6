# WBS 5.3.1 — Flashcard domain/data packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — children A, B, C merged |
| Owner/domain | Flashcard / Domain |
| Depends on | `5.2.6` — Done (Deck block complete) |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.3.1-01` |
| Test | `TEST-WBS-5.3.1-01` |

## Canonical inputs

- `create-flashcard.md` (required term/meaning per VAL-001; trim outer
  whitespace, keep internal line breaks; duplicate detection before
  commit, never overwriting), `resolve-duplicate-flashcard.md`
  (candidates by normalized content within the pair scope; keep-both
  persists separate id/progress).

## Child boundaries (one child per PR)

| Child | Scope |
| --- | --- |
| **A** | Card text validation/identity, duplicate-candidate query, `CreateFlashcardUseCase` over atomic op 1 |
| **B** | Child-content management use cases: translations (VAL-001 + ordered, dedup), tags (TAG-001..006), audio refs |
| **C** | Edit/hide/delete/move use cases + property/decision-table evidence |

## Child A — create + duplicate candidates (Done, 2026-07-19)

- **Schema**: `flashcards.normalized_term` (indexed) — SQLite `lower()`
  is ASCII-only, so the Unicode-correct identity is computed in Dart
  and stored; snapshot + verifier helpers re-exported (still v1).
- `card_text.dart` — `validateCardText` (typed `required`, trimmed
  display) + `normalizeCardTerm` (lowercase trimmed identity).
- Query `findDuplicateCandidates`: normalized-term match joined across
  the pair's decks, excluding soft-deleted; port
  `FlashcardRepository.duplicateCandidates`.
- `CreateFlashcardUseCase` → sealed `CreateFlashcardResult`:
  candidates return as `DuplicateCandidatesFound` **before commit**
  and only an explicit keep-both retry (`allowDuplicate`) proceeds;
  creation is atomic op 1 with kept-id idempotency; parent-deck
  targets fail with the stable `deck-mixed-content` code.
- 7 tests: atomic create + Box 0, typed required validation,
  cross-deck candidate with nothing committed, keep-both second card,
  soft-deleted exclusion, kept-id retry, mixed-content rejection.

## Child B — child-content management (Done, 2026-07-19)

- **Normalization foundation**: `StringUtils.nfc` (unorm_dart) +
  `caseFolded`; `validateCardText`/`normalizeCardTerm` now apply
  VAL-001 NFC, so composed/decomposed Vietnamese resolves one identity.
- `tag_label.dart` — TAG-001..003: NFC outer-trimmed display label,
  case-folded normalized uniqueness key.
- Queries (`card_children.drift` + create-flow reuse): translation
  edit/park+set order (two-phase permutation under the uniqueness
  constraint), tag usage count/delete, and the shared
  `touchFlashcardVersion` bump; `attachTag` is now INSERT OR IGNORE
  (TAG-004).
- Repository: every child mutation commits with the card version bump
  in one transaction; `resolveTagByLabel` resolves concurrent
  same-label creation through the unique constraint to the winner;
  `deleteTagIfUnused` is transactional (TAG-006); translation removal
  resequences survivors contiguously.
- Use cases: `ManageCardTranslationsUseCase` (add/edit/remove/reorder,
  normalized-duplicate block vs primary + siblings, complete-permutation
  validation), `ManageCardTagsUseCase` (attach-by-label idempotent,
  detach, delete-unused), `ManageCardAudioUseCase` (metadata add/remove).
- 16 tests: ordering/version bumps, blank/duplicate blocks (incl.
  composed-vs-decomposed collisions), contiguous re-sequencing,
  permutation validation, tag NFC/case resolution keeping the first
  display spelling, idempotent attach, TAG-005/006, concurrent
  same-label winner, audio add/remove + typed validation.

## Child C — lifecycle use cases (Done, 2026-07-19)

- Repository: `editCardContent` (content-version-guarded rewrite —
  a stale expected version fails typed as `stale-version`, never
  silent last-write-wins) and `deleteCardCascade` (children + current
  scheduling state + tombstone in one transaction; finalized session
  history untouched).
- Use cases: `EditFlashcardUseCase` (required/VAL-001 revalidation,
  duplicate candidates across the pair excluding self, sealed
  `EditFlashcardResult`, keep-both retry), `HideFlashcardUseCase`
  (content/progress untouched; idempotent), `DeleteFlashcardUseCase`
  (idempotent tombstone command; confirmation is UI scope),
  `MoveFlashcardUseCase` (source/Parent/cross-pair rejected — Parent
  via the 4.3 exclusivity triggers; id/content/children/progress
  preserved).
- 14 tests map the four specs' acceptance criteria, including the
  stale-version guard, review-then-keep-both editing, Leaf→Empty
  derivation after the last delete and atomic move preservation.

## Acceptance and test procedure

`AC-WBS-5.3.1-01`: required multilingual content is typed-validated;
duplicate candidates match normalized content across the pair and
never auto-overwrite; the create transaction is atomic with
idempotent retry; child content and lifecycle land with B/C.

`TEST-WBS-5.3.1-01`: per-child suites in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.3.1
  flips Done when C merges; `5.3.2+` (create-card UI) follows.
