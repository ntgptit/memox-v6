# WBS 5.1.1 — Language Pair domain/data implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Language Pair / Domain |
| Depends on | `4.10` — gate PASSED |
| Decision gates | DG-01 (business flows Accepted) |
| Acceptance | `AC-WBS-5.1.1-01` |
| Test | `TEST-WBS-5.1.1-01` |

## Canonical inputs

- `docs/business/language-pair/{create,select,remove}-language-pair.md`:
  no silent duplicates (offer the existing pair); selection by stable
  id, never label; removal guarded by owning decks.
- Validation catalog: source/target present, supported, distinct;
  normalized pair unique.
- Guard: use cases live in `lib/domain/usecases/**` with the
  `_usecase.dart` suffix.

## Scope

- `lib/domain/language_pair/language_pair_key.dart` — the normalized
  identity: lowercase trimmed codes as `learning|native`, built through
  `StringUtils`.
- `lib/domain/language_pair/supported_languages.dart` — the v1
  selectable catalog (12 languages, native + English names as data, not
  l10n copy); additive to extend.
- `ValidationFailure` joins the taxonomy (field + stable code:
  `required`/`unsupported`/`not-distinct`/`unknown`) with l10n
  fallback copy in `MxActionErrors`.
- `lib/domain/usecases/language_pair/`:
  - `create_language_pair_usecase.dart` — fail-fast typed validation;
    duplicate returns `LanguagePairAlreadyExists(existing)` (sealed
    result — the flow decides "use existing"); stable identity from the
    injected id/clock ports; a lost create race resolves idempotently
    to the winner.
  - `select_language_pair_usecase.dart` — selection persisted by
    stable id as a versioned preference; `activePair()` resolves it and
    degrades to null on removed pairs or corrupt payloads.
  - `remove_language_pair_usecase.dart` — the Deck dependency guard
    (`ConflictFailure(code: 'deck-dependency')` while decks exist);
    removing the active pair clears the stored selection first.
- Port additions: `LanguagePairRepository.deleteById`,
  `DeckRepository.countForLanguagePair` (+ the SQL-first
  `countDecksForLanguagePair` query).
- `test/domain/usecases/language_pair_usecases_test.dart` — 8 tests
  over real Drift repositories with the 1.10 fakes: key normalization,
  stable-identity create, duplicate-returns-existing, the three typed
  validation codes, selection round-trip + unknown rejection, the deck
  guard, and active-selection cleanup on removal.

## Acceptance and test procedure

`AC-WBS-5.1.1-01`: create/select/list/remove flow through typed use
cases; duplicates are never silently created; identity is stable and
injected; the deck guard blocks removal; no UI or provider code in
this child (that is 5.1.2).

`TEST-WBS-5.1.1-01`: `language_pair_usecases_test.dart` in every gate.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `5.1.1` Done; `5.1.2` (first-run
  language UI) is next, consuming these use cases via providers.
