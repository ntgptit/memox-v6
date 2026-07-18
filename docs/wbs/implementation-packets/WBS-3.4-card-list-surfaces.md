# WBS 3.4 — `MxCard`, list and surface primitives implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **Ready** — child A Done (2026-07-19); children B–C pending |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `3.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.4-01` |
| Test | `TEST-WBS-3.4-01` |

## Canonical inputs

- Kit `components/surfaces/MxCard.prompt.md` (frozen) + `.card` CSS:
  elevated default (surface + shadow-card), flat (hairline border),
  muted (surface-sunken ground family), primary (brand solid +
  shadow-fab), primary-soft (tint); padding default space-6 / pad-sm
  space-4 / pad-lg space-6 (values follow the kit exactly); interactive
  adds hover shadow-lg lift, press scale 0.985 and role=button; no
  nested interactives (constraints matrix).
- Kit `MxList.prompt.md`, `MxIconTile.prompt.md`,
  `MxSectionHeader.prompt.md` + their CSS (children B–C inputs).

## Child boundaries (XL rule)

| Child | Boundary | Status |
| --- | --- | --- |
| A | `MxCard`: five variants, padding steps, foreground inheritance for brand fills, interactive behavior (tap/hover-lift/press-scale/focus/semantics), long-content wrap evidence | **Done** (2026-07-19) |
| B | List primitives: `MxList` spacing/dividers contract, list row anatomy, `MxIconTile` | Pending |
| C | `MxSectionHeader` (title/caption/action), divider primitives, semantic tap-behavior matrix across the family | Pending |

## Scope — child A (this delivery)

Create:

- `lib/presentation/shared/widgets/mx_card.dart` — `MxCard` per the
  contract above; children inherit the variant foreground through
  `DefaultTextStyle`/`IconTheme`; interactive mode composes `MxTappable`
  (tap/focus/overlays) with kit hover-lift and press-scale motion at
  duration-fast/ease-standard; content-driven height, never clipped.
- `test/.../mx_card_test.dart` — 8 tests: variant grounds/shadows/
  borders, brand foreground inheritance, padding steps, no tap surface
  when static, interactive tap + hover lift + press scale (real mouse
  gestures), 320px long-content wrap.

Out of scope for child A: list/tile/header primitives (B–C), golden
catalog (3.11/3.12).

## Acceptance and test procedure

`AC-WBS-3.4-01` (child A portion): every variant × padding × interactive
state matches the kit values through token accessors; interactive cards
are single tap targets with button semantics. Full canonical gate passes.

`TEST-WBS-3.4-01` (child A portion): `mx_card_test.dart` in every gate.
Run once through `node tool/verify/run.mjs`.

## Failure and completion

- Child B promotion requires child A merged and green; the WBS `3.4` row
  stays Ready until child C completes.
