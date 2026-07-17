# AGENTS.md — memox_v6 workspace router

MemoX v6 — a local-first flashcard / spaced-repetition study app. **Flutter**,
multi-platform (Android, iOS, web, desktop).

## Design — single source of truth

The project design kit is **MemoX Design System v4**, at:

```
docs/design/MemoX Design System_v4/
```

It defines every visual value (deep-violet palette, Plus Jakarta Sans, 4px spacing,
`--memox-*` tokens) and the frozen `Mx*` component contract. For any UI, theming,
or visual decision, use the **`memox-design` skill** (`.claude/skills/memox-design/`,
or run `/memox-design`) — it explains how the kit's tokens map onto Flutter
`ThemeData` / theme extensions and `Mx*` widgets. Never invent colors, spacing, or
type scales; pull exact values from `tokens/*.css`.

Golden rule: changing a **value** is free; changing a **name or id** breaks the system.

## Code standard — main guard

All code is verified by **code-verification-guard** (git submodule at
`tools/code-verification-guard`) against the `memox` ruleset. It runs at pre-commit,
in CI, and as a Claude Code Stop hook. See `docs/code-verification-guard.md`. Do not
weaken rules to pass — fix the code (or the rule, in the guard repo).

## Stack conventions

- **State:** Riverpod (annotation + generator). Providers/notifiers via `@riverpod`;
  run codegen with `dart run build_runner build`.
- **i18n:** all user-facing copy through generated `AppLocalizations` (`context`
  l10n), backed by `lib/l10n/*.arb`. No hardcoded UI strings. Generated output
  (`lib/l10n/generated/`) is gitignored and regenerated automatically.
- **Generated code** (`*.g.dart`, generated l10n) is gitignored — regenerate, don't commit.
- **Design system:** prefer `Mx*` widgets and theme accessors over raw Material
  widgets and hardcoded colors (enforced by the guard).

## Verification

After changes, run the strongest available check: the guard
(`python tools/code-verification-guard/guard/run.py check --project . --ruleset memox
--profile local`), plus `flutter analyze` and `flutter test`.
