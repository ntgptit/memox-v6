# Scope statement — MemoX Design System v4

> Product decisions ratified 2026-07-18. This document is the canonical design-scope
> contract. It supersedes the historical React Native / phone-portrait assumptions while
> preserving every frozen `--memox-*`, `Mx*`, and `data-mx-node` identifier.

## Product and implementation target

MemoX v6 is a **Flutter, local-first, multi-platform application**. The CSS, HTML and JSX in
this kit are reference/prototype artifacts; production maps the same values and semantic ids to
Flutter `ThemeData`, `ThemeExtension`s and `Mx*` widgets.

| Tier | Platform/profile | Release expectation |
| --- | --- | --- |
| **Tier 1** | Android phone and tablet; Flutter Web on phone, tablet and desktop browsers | Must satisfy responsive reflow, portrait/landscape where the window permits it, keyboard/pointer, safe-area and accessibility gates before release. |
| **Tier 2 / roadmap** | iOS, Windows, macOS and Linux | Preserve framework-neutral contracts; platform certification and platform-specific QA are deferred. |
| **Deferred profile** | RTL application chrome | New layout uses logical direction and must remain RTL-ready; v1 ships `en` and `vi`, both LTR. |

Android foldables use the Tier-1 window-size profiles. A separated hinge must be treated as an
unsafe region; a dedicated dual-pane posture is roadmap work until runtime hinge evidence exists.

## Domain decisions reflected by the kit

### Deck kinds are exclusive

There is one `Deck` aggregate, with three mutually exclusive kinds:

- **Empty** — no direct cards and no child decks; the first content choice establishes the kind.
- **Leaf** — owns direct flashcards and has no child decks.
- **Parent** — owns child decks and has no direct flashcards.

A nested deck is still a Deck (`parentId != null`), not a separate Subdeck aggregate. There is no
mixed Deck and **no Leaf→Parent conversion flow**. A user who needs a different structure creates
a new Parent Deck and explicitly moves content through a separately specified transfer operation.
Historical `convert-*` shot/state identifiers are deprecated compatibility ids and are not valid
entry states or implementation requirements; they must not schedule a conversion mutation.

Hierarchy remains **Library › Deck (→ nested Deck…) › Flashcard**. Frozen `SubdeckList` names and
`subdeck-*` / `subdeck-list/*` ids remain compatibility identifiers; user-facing copy says “Deck”.

### Study entry points

| Session type | Entry | Contract |
| --- | --- | --- |
| **New learning** | eligible Leaf Deck / Today | Runs Review → Match → Guess → Recall → Fill in order for each eligible card. Completion of all five stages activates Learning Progress. |
| **Due review** | Today / Deck due action | Reviews the persisted due queue; it does not run the five-stage learning pipeline. |
| **Relearn** | terminal wrong/sticky-wrong outcome | Runs the explicit relearn queue; it is not an implicit sixth new-learning stage. |
| **Practice / Single mode** | Mode Picker | User selects exactly one mode and then activates the explicit **Start session** CTA. Practice does not activate Box 0 cards or schedule SRS. |

Guess requires **at least five distinct normalized meanings**. Recall has a deterministic
**20-second** countdown; timeout is an explicit terminal answer state and never silently becomes
“Forgot”.

### SRS settings

The Leitner 8-box schedule is a fixed versioned policy. Settings may display the policy id, eight
boxes and intervals as **read-only information**. Only reminder/notification preferences are
interactive; rows showing box count or intervals must not use chevrons, edit affordances or value
pickers.

## Adaptive layout contract

The canonical matrix and Flutter mapping live in
[`guidelines/flutter-adaptive-layout.md`](guidelines/flutter-adaptive-layout.md). Summary:

| Profile | Window width (logical px) | Navigation | Content strategy |
| --- | ---: | --- | --- |
| Compact | `< 600` | bottom destinations | one pane; 16px gutter; scroll body |
| Medium | `600–839` | navigation rail | one pane or supporting pane; readable content capped |
| Expanded | `>= 840` | navigation rail | centered max-width content; list/detail may use two panes |
| Compact height | `< 480` usable height | profile above, reduced chrome | primary action remains reachable; overlays scroll |

The historical 390×780 PNGs remain **compact-profile visual baselines**, not evidence for medium,
expanded, landscape or keyboard/pointer readiness.

## Language and direction

- Shipping UI locales: **English (`en`) and Vietnamese (`vi`)**.
- All user-facing production copy maps to Flutter `AppLocalizations`; no literal UI strings.
- Locale-aware date, time, number and plural formatting is mandatory.
- Study content can use any script independently of the application locale.
- RTL chrome is deferred, but logical start/end properties and directional-icon ownership are
  mandatory so RTL can be enabled additively.

## Shared visual language and platform adaptation

MemoX uses one branded visual language. Platform adaptation changes presentation and input
behaviour, not semantic names:

| Concern | Android | Web | Frozen semantic owner |
| --- | --- | --- | --- |
| Navigation | system back + app back; bottom/rail by width | browser history + app back; bottom/rail by width | `MxScaffold`, `MxBottomNav`, route contract |
| Pointer/keyboard | hardware keyboard optional but supported | required: Tab, Shift+Tab, Enter/Space, Escape and visible focus | each interactive `Mx*` widget |
| Sheets/dialogs | bottom sheet compact; dialog medium/expanded | bottom sheet compact; dialog/popover medium/expanded | `MxSheet`, `MxDialog`, `MxMenu` |
| File/media/time picker | Flutter/platform capability adapter | browser capability adapter with cancel/error fallback | feature interaction contract |
| Safe area | system bars, cutouts, IME | browser viewport, virtual keyboard, resize | `MxScaffold` |

Custom branded controls remain visually consistent, but must expose Flutter semantic roles and
expected Web/Android interaction behaviour.

## Supported design foundations

- Light and dark themes; high-contrast tokens exist but release evidence is tracked separately.
- Plus Jakarta Sans with Vietnamese coverage and documented CJK system fallback.
- Material Symbols Rounded with offline/runtime asset packaging required by implementation.
- Minimum touch target 48 logical px; visible focus for keyboard/pointer.
- Reduced-motion profile; no task relies on animation, haptic, sound or gesture alone.
- Flat token fills; no gradients, photography or glassmorphism.

## Release evidence boundary

“Specified” is not the same as “verified”. Tier-1 sign-off requires all of the following:

1. Android compact + medium portrait and landscape evidence.
2. Web compact + medium + expanded evidence at breakpoint boundaries.
3. Keyboard/pointer focus-order and activation walkthrough on Web.
4. 200% text, `en`/`vi`, dark/light, reduced-motion and offline/error state coverage.
5. Representative list/detail collapse, adaptive overlay and compact-height recordings.
6. Zero open P0/P1 in `mobile-design-kit-audit-v5/issue-register.md`.

Until that evidence exists, the design kit status is **BLOCKED for Tier-1 release**, even when
token/component structural validation passes.

## Artifact status taxonomy

| Status | Meaning | Where recorded |
| --- | --- | --- |
| **Current** | Supported contract for MemoX v6 | this file, component prompts, specs |
| **Future** | Defined roadmap item, not a release dependency | `CHANGELOG.md` `[Unreleased]`, issue register |
| **Deprecated** | Kept only for compatibility; new usage blocked | `governance/deprecation-policy.md` |

Current deprecated artifacts include legacy Tokyo colour values,
`--memox-appbar-lg-height`, and the non-routable `flashcard-list/convert-*` state family.

## Accepted non-blocking scope decisions

- Continuous swipe/drag is not a primary product interaction. Every task has a button/keyboard
  alternative. A future gesture-primary feature must add follow-finger/cancel/commit evidence.
- Tier-2 platform certification is roadmap work. This does not waive Tier-1 Web/Android gates.
- A dedicated foldable dual-pane posture is roadmap work; resize, safe-region and hinge avoidance
  remain required for Android.

## Design artifact caveats

- Existing still frames primarily cover compact 390×780; they are historical references.
- The prototype catalog is not the production localization source; Flutter ARB files are.
- A bespoke brand app icon still requires owner-provided source artwork and export evidence.
- No release claim may cite unavailable `npm`, parity or screenshot commands as passed evidence.
