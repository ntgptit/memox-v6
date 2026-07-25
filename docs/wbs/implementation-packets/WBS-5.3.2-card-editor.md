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

**`MX-VIS-055` duplicate — PASS, 1.97% light / 2.20% dark.** Measured through
the real create path (save a card, add a second with the same term); no fixture
override, because detection reads normalized content only that path writes.

Closing it exposed a shared-widget defect. `MxBanner` put its action inside the
outer row, as a sibling of the `Expanded` text, so the action claimed its
intrinsic width first and starved the message: the duplicate banner's two
buttons squeezed the text into a ~90px column that wrapped to one word per line
and grew the banner to four times its height. The kit's `ActionCallout` has two
layouts and picks by *title* — untitled keeps the action inline, titled puts it
**inside** the text column below the body. All three `action:` call sites in
this repo pass a title, so every one took the wrong branch. Fixing that alone
moved this state 18.12% → 6.34%.

The rest is the kit's stacked decision shape, landed as `MxBanner.stacked`:
a regular-weight message rather than a bold title, and the controls on their
own row at the padding edge rather than indented past the glyph.

It began as a feature-local `DuplicateReviewBanner`, following the kit's note
that "the stacked 2-button flashcard-editor DupBanner … stay[s] local". The
guard rejected it — `memox.design_system.no_theme_token_imports`: feature-layer
code may not import `app_spacing.dart` / `app_border_radii.dart`, and there is
no context accessor for either, so anything needing raw spacing or radius
belongs in the shared layer. The kit's "local" is about design-system
organisation, not this repo's layering. FD-10 already covers the case — add a
shared variant when the kit contract supports one — and it plainly does, so
the shape lives as a second `MxBanner` layout instead of a near-duplicate
widget.

That took two measurements to get right, and the first was worse: as a `Wrap`
the buttons stacked and centred and the state regressed to 10.39%. `Align` +
`Row(mainAxisSize.min)` fixed it — the banner is stretched by the form column,
so intrinsic-width buttons centre themselves in the leftover space unless
pinned. Reverting on the measurement rather than defending the change is what
found it.

**`MX-VIS-056` submitting — PASS, 1.02% light / 1.27% dark.** The write is
pinned on a completer nothing resolves, the same shape as `MX-VIS-011` one
layer up, so the frame is held rather than raced against a write that finishes
in milliseconds. The editor already implemented the state faithfully — fields
`enabled: !isSubmitting`, Save swapped for "Saving…" — so nothing needed
building.

**`MX-VIS-057` submit-error — light PASS 1.58%, dark 4.92% (over).** Measuring
it found the error banner using the wrong layout: the call site passed the
message as `title`, which is the *decision* shape (bold heading, action stacked
beneath), where the kit draws a recoverable failure as the untitled inline
banner — one regular-weight sentence with `Try again` trailing it on the same
row. Correcting the call site moved it 3.36% → 1.58% light and 9.99% → 4.92%
dark.

The dark residual is colour, not composition: the same widget tree passes in
light. That belongs to the dark-token sweep rather than to this row.

**Finding for whoever closes these:** the kit's `--submitting` and
`--submit-error` shots are both drawn in the **edit** variant — the app bar
reads "Edit card", because the kit's JSX gives "New card" only to
`view === 'create'`. Both journeys here are create. `MX-VIS-056` passes anyway,
which puts that difference at roughly 1%, so it is not the dark blocker — but
neither shot can reach zero from a create journey, and an edit-mode journey
would need a failing *edit* write path alongside the create one.

**Remaining child-B scope:** `submit-success` and the dirty-discard overlay.
The kit has **ten** editor states; the register now carries **four**.
`submit-success` needs a product decision first — the kit keeps the user in the
editor with Save reading "Done", while this app pops back to the deck.

## Acceptance and test procedure

`AC-WBS-5.3.2-01`: the editor creates learnable cards atomically in
the target deck with typed validation and duplicate review before
commit; drafts survive failure; every shipped state carries kit-parity
evidence (<3%) per the 3.15 rule.

`TEST-WBS-5.3.2-01`: widget + parity suites per child in every gate.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.3.2
  flips Done when C merges; `5.3.3` (flashcard list) follows.
