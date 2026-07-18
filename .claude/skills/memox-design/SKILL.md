---
name: memox-design
description: MemoX design system — the project's single source of truth for visual design (deep-violet palette, Plus Jakarta Sans, 4px spacing, --memox-* tokens, frozen Mx* component contract). Use when building, reviewing, theming, or prototyping ANY MemoX UI, choosing colors/spacing/typography/radius, or when the user runs /memox-design. This project is Flutter, so map the kit's CSS token values onto Flutter ThemeData / theme extensions and the Mx* widget family.
user-invocable: true
---

# MemoX Design System (project design kit)

> Compatibility mirror for Claude Code. The canonical repository skill is
> `.agents/skills/memox-design/SKILL.md`; keep this mirror synchronized from the
> canonical file instead of editing both independently.

The canonical design kit lives at:

```
docs/design/MemoX Design System_v4/
```

It is the **single source of truth for every visual value** in MemoX: color,
typography, spacing, radius, elevation, motion, and the `Mx*` component contract.
Always read the kit before making any visual decision — never invent colors,
spacing, or type scales.

## Platform note — this project is Flutter, not React Native

The kit was authored with a React Native reference and ships CSS/HTML as the
design/prototyping layer. **`memox_v6` is a Flutter app.** The mapping is:

- **Token values** (`tokens/*.css`, `--memox-<role>`) → Flutter theme constants /
  `ThemeExtension`s under `lib/core/theme/`. Values are identical; only the syntax changes.
- **Component base classes** (`MxCard` ↔ `.card`, `MxButton` ↔ `.btn`, …) → Flutter
  `Mx*` widgets. The **names are a frozen contract** shared with the code guard
  (`memox` ruleset already forbids raw Material widgets in favor of `Mx*`).
- **Screens / `data-mx-node` ids** → stable semantic ids kept the same across platforms.

The golden rule (from the kit): **changing a value is free; changing a name or id
breaks the system.** Token names are additive-only.

## How to use this kit

1. **Read first:** `docs/design/MemoX Design System_v4/readme.md`, then `SKILL.md`
   and `SCOPE.md` in that folder for the full contract and what's in/out of scope.
2. **Tokens:** pull exact values from `tokens/*.css` (colors, typography, spacing,
   radius, elevation, motion, opacity, icon-size, stroke). Deep-violet primary
   `#4b3a8c`, accent `#7355d6` (light) / `#a88fff` (dark); light canvas `#f6f5fc`,
   dark canvas `#141220`. Light in `:root`, dark in `[data-theme="dark"]`.
3. **Components:** consult `components/<group>/*.prompt.md` for each `Mx*` component's
   variants and stable base class before building the Flutter equivalent.
4. **Guidelines & governance:** `guidelines/` (color/type/spacing/elevation, i18n,
   focus order, overlays) and `governance/` (contributing, versioning, promotion,
   theme-onboarding) define the rules; follow them, don't restyle around them.
5. **Content/voice:** sentence case, calm encouraging tone, numbers lead, Material
   Symbols icons (no emoji) — see the CONTENT FUNDAMENTALS section in `readme.md`.

## Design checklist / audit — REQUIRED for app design or kit redesign

When **designing app screens/flows** or **redesigning the kit** (tokens, components,
patterns, themes), the checklist source is:

```
docs/design/mobile-design-kit-audit-v5/
```

48 KIT groups (`KIT-01`…`KIT-48`, 288 items) covering tokens, typography, spacing,
components, patterns, accessibility, responsive/adaptive, motion, dark-mode/high-contrast
QA, governance, and release readiness. Each item has **Cách kiểm** (how to verify) and
**Evidence mong đợi** (expected evidence); severities are gated **P0–P3** (P0 blocks
release, P1 blocks kit sign-off).

Use it like this:

1. Read `audit-rules.md` (marking, severity, per-group conditions) and
   `verification-methods.md` first — token-cheap boilerplate lives there, not per item.
2. Open only the `KIT-XX-*.md` groups relevant to the work (e.g. `KIT-25-form-patterns`,
   `KIT-30-loading-empty-error-va-offline`, `KIT-42-accessibility-end-to-end`).
3. Treat each item's criteria as acceptance criteria for the design; log gaps in
   `issue-register.md` with severity + owner + target, and honor the P0/P1 gates before
   calling design work done.
4. `scripts/validate.py` self-checks the checklist docs (broken links, duplicate ids /
   near-duplicate content) — run it when editing the audit itself.

Docs are intentionally bilingual (Vietnamese checklist prose; `Cách kiểm` / `Evidence`
may be English or Vietnamese). Don't "finish" a design without citing the relevant gates.

## Guardrails

- No raw `#rrggbb` / literal color or spacing values above the token layer — the
  code guard (`memox.design_system.*`, `flutter.no_hardcoded_color`) enforces this.
- No gradients, photographic imagery, or glassmorphism — depth is surface layering
  + shadow (light) / hairline rings (dark).
- User-facing copy flows through `AppLocalizations` (l10n), never hardcoded strings.

When invoked without specifics, act as an expert MemoX designer: ask what to build,
then produce Flutter UI (or an HTML prototype from the kit) grounded in these tokens.
