# Bundled fonts

## Plus Jakarta Sans (variable, wght 200–800)

- File: `PlusJakartaSans-Variable.ttf` — copied verbatim from the design kit
  (`docs/design/MemoX Design System_v4/fonts/PlusJakartaSans[wght].ttf`),
  renamed only to avoid bracket characters in asset paths.
- Designer: Tokotype (Gumpita Rahayu). Licensed under the
  [SIL Open Font License 1.1](https://openfontlicense.org);
  source distribution: [Google Fonts](https://fonts.google.com/specimen/Plus+Jakarta+Sans).
- Registered in `pubspec.yaml` as family `Plus Jakarta Sans`; the token layer
  (`lib/core/theme/tokens/app_typography.dart`) is the only place the family
  name is written.

CJK glyphs are intentionally not bundled: per the kit's `--memox-font-cjk`
contract, CJK content falls through to platform families (Noto/system CJK).
