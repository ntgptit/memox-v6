# Coverage report — 2026-07-18 rebaseline

This report separates **artifact inventory**, **historical evidence**, and **current Tier-1
verification**. A file existing on disk is not proof that a missing command was run.

## Current inventory

| Area | Current contract | Evidence status |
| --- | --- | --- |
| Platform | Flutter; Web + Android Tier 1 | Specified in `SCOPE.md`; medium/expanded Android/Web runtime evidence open |
| Screen manifest | 27 specs in `ui_kits/memox-app/specs/INDEX.md` | Manifest is manually rebaselined because its cited generator/registry is absent |
| Active registered state count | 213 after removing 3 conversion states and adding Recall timeout + 4 Today states | Source/spec count; fresh shots for additions open |
| Compact historical shots | Existing PNGs under `ui_kits/memox-app/shots/` | Visual references only; predominantly 390×780 |
| Themes | Light and dark token profiles | Token contract present; changed-screen re-shoot open |
| Locales | English and Vietnamese v1; RTL-ready/deferred | `vi` prototype seed and Flutter handoff present; complete ARB parity/runtime evidence open |
| Adaptive profiles | compact `<600`, medium `600–839`, expanded `>=840`, compact-height `<480` | Contract present; boundary screenshots/walkthroughs open |

## Historical evidence boundary

Existing 390×780 PNGs may support compact-profile comparisons for unchanged states. They do not
prove Web expanded layouts, Android tablet/landscape, keyboard/pointer behaviour, Vietnamese text,
new Recall timeout, new Today failure/recovery states, or the rebaselined Deck/Mode/SRS semantics.

Older documents cited these unavailable paths/commands:

- `package.json` / `npm run verify:ui-kit`
- `tool/ui_kit_shots/registry.mjs`, screenshot and contrast scripts
- `tool/parity/*` and `tool/a11y/*`

Those artifacts are not present in the current repository. Their historical reported results are
not current release evidence and must not be presented as PASS.

## Required Tier-1 evidence

| Axis | Minimum evidence | Status |
| --- | --- | --- |
| Responsive/adaptive | 320/390/599, 600/839, 840/1200/1440 plus compact height; representative list/detail and overlay transitions | **OPEN P1** |
| Android | phone/tablet portrait+landscape, system Back, IME, rotation/resize preservation, offline/restart | **OPEN P1** |
| Web input | Tab/Shift+Tab, Enter/Space, Escape, pointer, browser Back, focus restore | **OPEN P1** |
| Business reconciliation | exclusive Deck, Practice picker+Start, Guess≥5, Recall 20s, read-only SRS, distinct session types | Source updated; **fresh evidence OPEN P1** |
| Today | loaded/paused/offline/partial/error/empty/caught-up | Source updated; **fresh evidence OPEN P1** |
| Localization | complete `en`/`vi` ARB parity, 200% text, locale date/number/plural, screen-reader labels | **OPEN P1** |
| Accessibility | light/dark, 200%, reduced motion, high contrast, screen reader and focus order on current Flutter build | **OPEN P1** |

## Release conclusion

Structural documentation can be validated, but the MemoX v4 design kit is **BLOCKED for Tier-1
release sign-off** until the open P1 evidence in the audit register is attached and re-reviewed.
