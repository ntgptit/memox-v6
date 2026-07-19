# WBS 5.2.4 — Library and open Deck packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — children A, B Done (2026-07-19); C pending |
| Owner/domain | Deck / Presentation |
| Depends on | `5.2.2` — Done; owns the transferred 5.2.3 success callout |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.2.4-01` |
| Test | `TEST-WBS-5.2.4-01` |

## Canonical inputs

- `browse-nested-decks.md` (Library root, nested context, bottom nav
  only at root), `open-deck.md` (Empty/Leaf/Parent branching and per
  state CTAs), `create-deck.md` §7 (the transferred success surface:
  Library + highlighted deck + contextual callout) and §8 (the normal
  create dialog).

## Child boundaries (one child per PR)

| Child | Scope |
| --- | --- |
| **A** | Library root list (reactive, empty state) + the transferred first-run success callout with highlight + deck-detail navigation (placeholder target) |
| **B** | Open Deck: Empty/Leaf/Parent branching per `open-deck.md`, nested browse context |
| **C** | Create-deck dialog (§8), dense/deep/long-name/error/offline states, evidence |

## Child A — Library root + callout (Done, 2026-07-19)

- `WatchLibraryUseCase` + `libraryRootDecksProvider`: the active
  pair's root decks as a reactive stream (no pair → empty library).
- `LibraryScreen` (route `/library`): headline, reactive root list
  (name + optional description), empty-state message, per-row
  navigation to `/deck/:deckId`.
- **Transferred callout delivered**: first-run create success now lands
  in the Library; `FirstDeckCalloutViewmodel` (keep-alive, cleared on
  dismiss/open) drives the §7 callout — success banner, `Open deck`
  navigating to the new deck, dismiss ×, and the new deck's row
  highlighted.
- `DeckDetailPlaceholderScreen` keeps `/deck/:deckId` resolvable until
  child B ships the real open-deck screen (recorded placeholder).
- Test-harness note: Library renders a Drift stream; widget tests use
  bounded pumps plus a trailing flush pump instead of `pumpAndSettle`
  (the loading spinner never settles while a stream is in flight).

Recorded boundaries: bottom navigation appears at Library root per the
kit — the app-shell bottom-nav wiring stays with the Today owner
(5.7); sort/search/dense/deep states are child C scope.

## Child B — Open Deck branching (Done, 2026-07-19)

- `OpenDeckUseCase` + providers: the deck row plus **two reactive
  content streams** (children, active direct cards) — the screen
  derives Empty/Leaf/Parent from them per §5, so §7 transitions
  (first card → Leaf, content-based) update in place with no stored
  mode and no route duplication.
- `DeckDetailScreen` (real body replacing the A placeholder):
  - **Empty**: title/body + `Add card` and `Create nested deck` CTAs
    (activation owned by 5.2.5/5.3 and the C dialog — recorded);
  - **Leaf**: card-count summary + card rows (term + meaning), no
    nested-create anywhere;
  - **Parent**: nested-deck count + child rows **pushing** deeper
    (`pushDeckDetail`; `backFromDeck` pops one level, falling back to
    the Library) + `Create deck` CTA (C dialog);
  - **Not found**: message + Back to Library.
- 5 widget tests: all three branches, in-place Empty→Leaf transition
  driven by a live insert, nested browse down + back up, not-found.

Boundaries recorded: Search/More app-bar actions, skeleton loading and
the consistency-error surface land with child C's states pass;
aggregate card counts for Parent summaries need a subtree count query
(C).

## Acceptance and test procedure

`AC-WBS-5.2.4-01`: Library lists roots reactively with correct
Empty/Leaf/Parent branching on open; the first-run success callout
behaves per §7; all named states covered by C's evidence.

`TEST-WBS-5.2.4-01`: per-child suites in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.2.4
  flips Done when C merges; `5.2.5` follows.
