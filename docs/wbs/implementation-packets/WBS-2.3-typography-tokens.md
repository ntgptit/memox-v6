# WBS 2.3 — Typography/font tokens implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.1` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-2.3-01` |
| Test | `TEST-WBS-2.3-01` |

## Canonical inputs

- `docs/design/MemoX Design System_v4/tokens/typography.css` — 27 frozen
  tokens: 4 family stacks, 9 sizes, 5 weights, 5 line heights, 4 letter
  spacings; variable Plus Jakarta Sans (`wght` 200–800) shipped by the kit at
  `fonts/PlusJakartaSans[wght].ttf`.
- `docs/design/token-manifest.json` — the 27 tokens owned by this item.
- Kit contract: Vietnamese is fully covered by the primary family (explicit
  alias token); CJK must fall through to an explicit platform stack
  (KIT-09-04/KIT-37-02).

## Scope

Create:

- `assets/fonts/PlusJakartaSans-Variable.ttf` — copied verbatim from the kit
  (renamed to drop bracket characters) + `assets/fonts/README.md` with
  designer/OFL-1.1 attribution and the no-bundled-CJK rationale.
- `lib/core/theme/tokens/app_typography.dart` — families
  (`fontFamily`/fallback, mono fallback, `vietnameseFamily = fontFamily`,
  explicit `cjkFamilyFallback`), 9 sizes, 5 `FontWeight`s, 5 line-height
  multipliers, 4 em letter-spacings + `letterSpacingFor(em, fontSize)`
  converter; `byToken` maps per category keyed by frozen CSS names.
- `test/core/theme/typography_css_parity_test.dart` — re-parses the CSS at
  gate time: sizes/weights/line-heights/letter-spacings compared exactly,
  family contract (Vietnamese alias, CJK stack order) asserted.
- `test/core/theme/typography_render_test.dart` — Vietnamese and CJK fixture
  rendering through the token styles and the full bundled weight range.

Modify:

- `pubspec.yaml` — register the `Plus Jakarta Sans` font family.

Out of scope: semantic text roles/TextTheme (2.6/2.7), icon fonts (2.5),
bundling CJK glyphs (explicitly platform-fallback per kit).

## Acceptance and test procedure

`AC-WBS-2.3-01` is true only when:

1. The variable font asset is bundled and registered; the family name is
   written only in the token layer.
2. All 27 manifest tokens exist with exact kit values; letter spacing keeps
   the em semantics with an explicit px converter.
3. Vietnamese uses the primary family by contract; CJK has the explicit
   ordered fallback stack from the kit.
4. Parity + render tests pass inside the canonical gate.

`TEST-WBS-2.3-01`: `typography_css_parity_test.dart` (6 tests) and
`typography_render_test.dart` (3 tests) run in every `flutter test` gate.
Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Kit value change: update the token file, parity test confirms; names never
  change.
- Success: record register evidence, mark `2.3` Done, then author `2.4`
  (spacing/size/radius/stroke/elevation) next.
