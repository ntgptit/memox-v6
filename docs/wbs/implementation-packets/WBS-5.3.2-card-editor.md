# WBS 5.3.2 — Card Editor packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — child A Done (2026-07-19); B, C pending |
| Owner/domain | Flashcard / Presentation |
| Depends on | `3.12` Done, `5.3.1` Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.3.2-01` |
| Test | `TEST-WBS-5.3.2-01` |

## Canonical inputs

- `create-flashcard.md` (form archetype, single Save primary, target
  deck context, atomic save + initial progress, duplicate resolution
  before commit), `edit-flashcard.md` (version-guarded save),
  `manage-card-translations.md` (nested section), kit
  `flashcard-editor` (10 states; deck-driven language labels;
  dirty-cancel guarded by discard-confirm; sticky Save;
  progressive disclosure).

## Child boundaries (one child per PR)

| Child | Scope |
| --- | --- |
| **A** | Create state: modal editor shell (close + centered title), deck-context pill, deck-driven term/meaning fields, tags input (resolve + attach on save), create-another toggle, atomic save via `CreateFlashcardUseCase`, validation state; "Add card" CTA activates on the empty deck; kit parity for `flashcard-editor--create` and (unblocked) `empty-deck--default` |
| **B** | Duplicate resolution (4-way review), submitting/submit-error/submit-success, dirty-discard confirm |
| **C** | Edit mode (stale-version), additional-translations section, audio row, keyboard/more-options states; stale-target handling |

## Child B — findings before building

Reconciling the child-B scope against the kit and the business flows first,
rather than building from the packet line alone, changed what B needs to be.

**The 4-way duplicate decision is not a parity gap.** The packet reads
"Duplicate resolution (4-way review)", but the kit's `DupBanner.jsx` says
plainly that the banner *is* the specified surface — "This banner is the entry
point; the full compare/merge screen is built at implementation time" — and the
state matrix in `specs/flashcard-editor.md` lists CF-07's Edit / Open-existing /
Keep-both / Merge under "Business-required capability, pending build … These
surfaces are authored at implementation time." The shipped banner already
matches the kit: a warning tone, `View existing` as the emphasized action and
`Add anyway` as the ghost override. The compare/merge screen is unspecified
product — it has no shot, no JSX and no layout in any doc — so building it here
would be inventing design, the same call already recorded for `Deck.icon`.

**A defect blocked the child-B journey entirely.** The deck-detail *card-list*
branch shipped `MxButton(label: addCard, onPressed: null)` behind the comment
"Add card lands with the 5.3 flashcard flow" — the row that had already landed
as child A. Only the *empty*-deck branch was wired to `pushNewCard`. A deck
therefore accepted its first card and no others: the core loop was unreachable
past one card per deck, and every duplicate state is by definition a second
card. Three widget tests asserted the button was present and passed against the
dead control; the leaf test now asserts `onPressed` is non-null.

An audit of every other `onPressed: null` in `lib/presentation/features/` found
three, all *Import cards*, all correctly disabled pending WBS 8.x with accurate
comments. The Add card site was the only one whose blocking row had shipped.

The fix is deliberately the minimal one — wire the control that is already
there. The kit does not draw that control: `FlashcardList.jsx` gives a
populated leaf an `MxFab` (`ariaLabel="Add card"`) opening an `AddCardSheet`
with Add card / Import cards, not a full-width button under the list. So the
button was divergent before this change and still is; enabling it adds no
divergence, it makes an existing divergence usable. Replacing it with the
kit's FAB + sheet belongs to `MX-VIS-042`, which is Blocked on filter chips
(`10.2`), SRS badges (`5.4.2`) and the breadcrumb (`6.2`) — none of them this
row's to unblock, and none of them a reason to leave the app unable to hold a
second card.

**Remaining child-B scope** (next iteration): allocate `MX-VIS-055`+ for the
editor states the register never tracked — the kit has **ten**, the register
carries **one** (`MX-VIS-049` Create) — and measure `duplicate`, `submitting`,
`submit-error` and `submit-success`. The duplicate journey is now reachable
without a fixture override: save a card, add a second with the same term.

## Acceptance and test procedure

`AC-WBS-5.3.2-01`: the editor creates learnable cards atomically in
the target deck with typed validation and duplicate review before
commit; drafts survive failure; every shipped state carries kit-parity
evidence (<3%) per the 3.15 rule.

`TEST-WBS-5.3.2-01`: widget + parity suites per child in every gate.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.3.2
  flips Done when C merges; `5.3.3` (flashcard list) follows.
