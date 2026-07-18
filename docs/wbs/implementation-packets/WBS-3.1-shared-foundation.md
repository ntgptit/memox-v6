# WBS 3.1 — Shared text/icon/tappable foundation implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Flutter UI + Accessibility / Shared `Mx*` |
| Depends on | `2.10` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-3.1-01` |
| Test | `TEST-WBS-3.1-01` |

## Canonical inputs

- Theme/extension/responsive layers (wave 2) and the type-scale roles
  (2.6); Material Symbols contract from `AppIconSizes` (2.5).
- Guard contracts: shared-widget doc sections (marker-per-line
  `Purpose:`/`Use when:`/`Category:`/`Public API:` + bullets),
  `no_raw_ink_surface` (tap surfaces only via `mx_tappable.dart`),
  `no_direct_text_theme` (`MxText(role:)` is the feature text API),
  `no_hardcoded_radius` (BorderRadius literals only in the token layer),
  `string_normalization_via_string_utils`.
- `material_symbols_icons ^4.2951.0` — checked on pub.dev 2026-07-19;
  depends only on the Flutter SDK, no analyzer involvement, resolves
  cleanly on the pinned toolchain (the 2.5 packet named it the approved
  vehicle).

## Scope

Create:

- `lib/presentation/shared/widgets/mx_text.dart` — `MxText` with the
  eight kit roles; caption/overline default to secondary text color;
  overline uppercases via `StringUtils` (kit "caps").
- `lib/presentation/shared/widgets/mx_icon.dart` — Material Symbols
  Rounded adapter at token sizes, default `colors.text`.
- `lib/presentation/shared/widgets/mx_tappable.dart` — the shaped tap
  primitive: state layers from interaction tokens, keyboard focus ring
  (focus-ring color × stroke-focus width, animated at duration-fast),
  48px minimum touch target, button semantics; the only
  `InkWell` call site.
- `lib/presentation/shared/widgets/mx_gap.dart` — const 4px-rhythm gaps.
- `lib/core/theme/tokens/app_border_radii.dart` — named `BorderRadius`
  shapes over the radius tokens (only legal literal site).
- `lib/core/utils/string_utils.dart` — central trimming/case
  normalization home required by the guard.
- `test/presentation/shared/widgets/mx_foundation_test.dart` — role
  styles/colors, overline caps, icon size/color, tap + semantics
  (flags/actions), 48px target, keyboard focus ring, disabled state,
  gap sizes.

Modify: `pubspec.yaml` (+`material_symbols_icons`).

Out of scope: buttons (3.2), fields (3.3), cards/surfaces (3.4), shells
(3.5), the full variant×state golden catalog (3.11/3.12).

## Acceptance and test procedure

`AC-WBS-3.1-01` is true only when:

1. All four primitives carry the guard doc contract and pass every
   shared-widget doc rule.
2. `MxTappable` is the sole ink surface; focus ring, state layers and
   touch minimum are token-true and test-verified.
3. Icon glyphs resolve through the Material Symbols Rounded package at
   token sizes.
4. Full canonical gate passes with zero guard errors.

`TEST-WBS-3.1-01`: `mx_foundation_test.dart` (9 tests) in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `3.1` Done, then author `3.2`
  (`MxButton` family) next.
