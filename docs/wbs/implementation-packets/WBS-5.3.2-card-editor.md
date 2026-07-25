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

### Chasing the dark residual — two wrong answers, then the diff image

Worth recording as method, because both hypotheses were plausible and both were
wrong, and each cost a full measurement to disprove.

*"It is a dark colour token."* Sampling the two renders at the page background,
banner fill, field fill and sticky footer returned **identical** values in
every position. Not colour.

*"It is the app-bar title."* The kit's `--submitting` and `--submit-error`
shots are both drawn in the **edit** variant — they read "Edit card", because
the kit's JSX gives "New card" only to `view === 'create'` — while both
journeys were create. Rebuilding `MX-VIS-057` as a genuine edit journey (save a
card, reopen it, edit, fail the *edit* write) moved the number
4.92% → 4.94%. The title contributes nothing measurable.

The diff image, which should have been the first thing read rather than the
third, shows the actual cause: the residual is spread across the **lower**
form. The shot embeds an additional-translation row ("Another meaning") and tag
content that the journey never creates. That is the same class as
`MX-VIS-036`/`037` — content baked into a shot that the flow does not produce —
not a defect in the widget tree.

Dark fails where light passes because light-on-dark glyph edges carry larger
per-pixel deltas than dark-on-light, so an identical text mismatch costs
roughly three times as much.

The edit journey is kept even though it did not move the number: the shot *is*
the edit variant, so the journey now matches what it is being compared against.

**Note the earlier claim in this packet — "the dark residual is colour, not
composition" — was wrong on both counts.**

**`MX-VIS-058` validation — PASS, 2.15% light / 2.46% dark.** Child A's state,
never tracked until now. A required field reports its error once *touched*,
never on arrival — a pristine form must not greet the user with two complaints
— so the only production path to the kit's both-errors frame is the one a user
takes: type into each field, then clear it. Loading the form cannot reach it.

The capture needed focus parked on the inert deck-context pill first.
`fillField` blurs with Tab, and in this form Tab lands on the *next* text
field, so a caret kept blinking and `expectStableCapture` rightly refused three
disagreeing settles. Worth knowing for the remaining states: any editor capture
that ends on a text field needs the same treatment.

**The dirty-discard overlay has no shot, and should not get one.** The kit's
JSX header names `discard-confirm` in its list of ten states, but there is no
`flashcard-editor--discard-confirm` shot and the state matrix in
`specs/flashcard-editor.md` never mentions discard. The ten shots that do exist
match the spec matrix exactly — and include `keyboard-open`, which that same
JSX header omits. The header comment is the odd one out, not the shot set.

The behaviour is covered where it belongs, by widget test: *"a dirty close asks
before discarding"* asserts the confirm dialog and the Keep-editing path.
Nothing to measure, nothing missing.

**Child B is complete except `submit-success`,** which is a product decision
rather than a build: the kit keeps the user in the editor with Save reading
"Done", while this app pops back to the deck on success. The two cannot both be
right, and the kit shot cannot be reached from behaviour the app does not have.

The register now carries **five** of the kit's ten editor states
(`create`, `duplicate`, `submitting`, `submit-error`, `validation`). The
remaining five — `edit`, `additional-translation`, `audio-generating`,
`keyboard-open`, `submit-success` — are child C's, plus that decision.

## Child C — measured before building

`MX-VIS-059` edit — **7.00% light / 7.54% dark, blocked on this child's own
scope.** Measuring first turns "edit mode, translations, audio" from a scope
line into an itemised list of what is actually missing.

The journey builds the kit's own card — term 안녕하세요, meaning "Hello
(formal)", tags `#TOPIK_I` / `#인사` — and reopens it for edit, so the content
matches and the residual is structural. Three surfaces account for it:

| kit draws | this build has |
| --- | --- |
| a trailing **audio** control inside the Term field | no audio affordance (CF-05) |
| a **`+`** beside the Meaning label to add a translation | a separate "ADDITIONAL TRANSLATIONS" section with an "Add translation" row (CF-06) |
| tags as **chips** | a free-text tags field |

Adding the kit's content moved the number 6.76% → 7.00%, which is the right
signal to read carefully rather than revert: matching the card made the *tags*
mismatch bigger, because a populated free-text field diverges from chips more
than an empty one does. The journey keeps the kit's card — it is the card this
state is being compared against, and the residual should be structural rather
than partly incidental.

**Prefill is correct and was never in doubt after the capture:** both stored
values are painted in the render. The `toHaveValue` assertion that first failed
was a harness limit, not a defect — on CanvasKit the labelled proxy carries
only what the engine editor has *typed*, so a controller filled before the
field was focused reads empty in the DOM while the canvas paints it. The
controllers are covered by the widget test "prefills the card and keeps a clean
Save disabled". Any future spec asserting prefilled content needs the same
care.

### Progressive disclosure landed (2026-07-25)

The kit's header states the rule plainly: *"the default view shows only Term →
Meaning (+ tags); the translation and advanced options are one tap away"*, and
its `Field` carries a `labelAction` — an `add` icon button on the Meaning label
— with the translation slot rendering only in the `additional-translation`
view. This build rendered the translations section expanded at all times,
pushing Tags below it.

`MxFieldScaffold`/`MxTextField` gained `labelAction`, and the editor now hides
the translation slot until the `+` asks for it. A card that *already* carries
translations still shows them unasked — disclosure hides an empty slot, never
existing content.

The action is **overlaid** on the label line rather than placed in a row with
the label. Two reasons, both load-bearing: it has to stay outside the
`MergeSemantics` that gives the input its accessible name, or the merge
swallows the button — the same defect this scaffold already carried once — and
a row would narrow the input by the button's width, where the kit keeps the
input full-bleed under a label line the action merely sits on.

Measured effect on `MX-VIS-059`: 7.00% → 6.53% light, 7.54% → 7.11% dark. Real
but modest, which is itself the finding — the translations section was not the
dominant contributor.

**The tags surface followed** as `MxTagField`: one bordered row holding the
`sell` glyph, plain chips and the entry caret. The entry lives *inside* the box
because the kit's empty state puts the "Add tags — e.g. …" hint there, which
only makes sense if the box is the input; the chips lose their remove `×`
because the kit draws none, and removal stays what `manage-card-tags.md`
already specified — tapping the chip. 6.53% → 6.14% light.

### `MX-VIS-059` PASSES at 0.82% / 1.63% — and the lesson is about attribution

Three changes, three modest gains, then one journey fix worth more than both
builds combined. Banding the diff by **contribution** rather than by percentage
is what found it: six of the 9.5 percentage points sat in the footer alone
(`y=1440..1499` carried 3.5pp at 91% of its pixels), while every content band
scattered 0.1–0.4pp.

The footer held a **dimmed Save** where the kit draws a full-strength one. Not
a styling defect: this app disables Save until content diverges
(`edit-flashcard.md` §6), and the kit's JSX sets `isDirty = view === 'edit'`,
so its edit state is a *dirty* edit. The capture was comparing a disabled
control against an enabled one. The journey now saves the card as "Hello" and
amends it to the shot's "Hello (formal)" in the editor: rendered content
matches and the form is legitimately dirty. **6.14% → 0.82%.**

Both builds were still right — they are what the kit specifies, and they hold
whatever the footer does. But three iterations were spent on surfaces worth
~0.5pp each while the dominant band went unexamined. Measure contribution
first, then build.

### `MX-VIS-060` additional translation — PASS at 1.40% / 2.56%

The method from the previous state paid off immediately. Banding by
contribution **before** touching anything showed the same footer signature —
6.03 of 10.32pp in three bands around the sticky Save — so the single change
that mattered was dirtying the form. A translation persists on its own, so
adding one leaves the *card content* clean and Save dimmed against the kit's
enabled one. 6.82% → 1.40% in one step, no product change at all.

**Defect found and fixed on the way: two controls sharing an accessible name.**
The Meaning label's disclosure `+` and the translations section's add button
both answered to "Add translation", so a screen-reader user could not tell them
apart — and the parity spec proved it by tapping the wrong one, re-triggering
disclosure instead of committing the typed translation. The kit avoids this by
scoping its label (`ariaLabel={'Add ' + alt + ' translation'}`). The disclosure
control is now "Add another meaning" (`showTranslationFieldLabel`), translated
in both ARBs; the committing control keeps "Add translation".

One harness note: the widget test taps that control **by icon**, not by
accessible name. A label that reaches the tree through `MxTappable` is not
visible to `find.bySemanticsLabel`, though Flutter Web exposes it fine — which
is why the Playwright spec can target the name and the widget test cannot.

### `keyboard-open` is unreachable, and that is the right answer

The kit draws this state with a **simulated software keyboard** rendered into
the mock — its own comment says so: "keyboard-open renders the populated edit
form with a simulated software keyboard raised". A headless-Chromium capture
has no OS keyboard and the app never draws one, so no journey can produce those
pixels. Recorded as `MX-VIS-061`, structurally unreachable, the same class as
`MX-VIS-013`/`027`. Faking a keyboard to satisfy a pixel gate would measure a
composition the product does not have.

What the state exists *for* is testable, and now is. KIT-25-04/35-01 puts the
SaveBar above the faux keyboard so the primary action is never covered; the
widget test "the Save bar stays above a raised keyboard" raises a 600px bottom
inset and asserts the button moved up into the area the keyboard left. Verified
by mutation: `resizeToAvoidBottomInset: false` on `MxScaffold` fails it
(expected ≤400, got 584).

**Remaining for child C:** only the Term field's audio control (CF-05), which
does not exist in this build at all — the kit itself defers it ("mock shows
play/generate only; business owns Generate / Attach file / Remove"), so it is
product to be authored rather than parity to be closed. Note
the kit's edit shot also carries the *create another* checkbox that
`specs/flashcard-editor.md` records as removed under CF-13 — a shot/spec
contradiction of the same class as `MX-VIS-036`/`037`, and small enough that
this state passes despite it.

## Acceptance and test procedure

`AC-WBS-5.3.2-01`: the editor creates learnable cards atomically in
the target deck with typed validation and duplicate review before
commit; drafts survive failure; every shipped state carries kit-parity
evidence (<3%) per the 3.15 rule.

`TEST-WBS-5.3.2-01`: widget + parity suites per child in every gate.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.3.2
  flips Done when C merges; `5.3.3` (flashcard list) follows.
