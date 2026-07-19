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

**Design / redesign checklist.** When designing app screens or redesigning the kit,
the checklist source is `docs/design/mobile-design-kit-audit-v5/` — 48 KIT groups
(288 items) with P0–P3 severity gates. Start from its `audit-rules.md` and
`verification-methods.md`, open the relevant `KIT-XX-*.md` groups, treat their items as
acceptance criteria, and log gaps in `issue-register.md`. The `memox-design` skill
explains how to apply it. Don't call design work done while a P0/P1 item is open.

## Business / domain — source of truth

The requirements and domain specification live at:

```
docs/business/
```

Markdown contracts organized by **business object / aggregate** (Deck, Language Pair, Flashcard,
Study Session, Learning Progress, Study Goal, Reminder, Preferences, Account, Backup,
Content Transfer) and supporting capabilities (Study Mode, Audio Playback, Study Streak /
Statistics, Search, Today Dashboard). Start from `docs/business/README.md` (object catalog)
and each folder's `README.md`. Screens **consume** these contracts; each object owns its
own invariants, lifecycle, and interaction contract — do not reinvent domain behavior in UI.

### ⚠️ Business ↔ design-kit conflict rule (STOP-and-ask)

Before developing any app feature, reconcile the **business spec** (`docs/business/`) with
the **design kit** (`docs/design/MemoX Design System_v4/` + audit checklist). **If they
diverge on any point** — a screen/flow, a domain concept (e.g. Deck vs nested-deck model),
a state, a capability, naming, or scope — **do NOT proceed on assumption and do NOT silently
pick one side. Stop and ask the user to resolve the divergence first**, quoting the specific
business point and the conflicting kit point. Only develop once the user has decided.

## Mandatory screen-delivery journey

Every new or materially changed screen, dialog, bottom sheet, or interactive UI
state must have a complete Flutter Web + Playwright journey before the work may
be called Done:

- Start from a fresh app launch at `/`, never from the target route or capture
  state. Traverse the navigation/first-use prerequisites and every owning
  business Master flow through visible, hit-testable controls.
- Use real browser pointer and keyboard input through Flutter's accessibility
  and native-editing bridge. Never call callbacks, providers, repositories, or
  mutate persisted state to skip UI steps.
- Fixtures may establish deterministic data preconditions only. They must not
  establish the current route, open surface, completed prerequisite step, or
  result that the journey exists to prove.
- Do not stop at the screenshot node. Continue through validation and mutation
  to an observable terminal outcome such as persisted success, recovery, or
  cancel, and assert the rendered result.
- Every spec names the owning `docs/business/**` Master flow plus every
  prerequisite flow/node used to reach it. A deep-link test is supplementary
  navigation coverage and never replaces this app-launch journey.
- CI may run headless, but every screen task must expose and successfully run a
  reproducible headed command so reviewers can observe the real clicks and text
  entry. Slow motion and a final hold are allowed for review.
- Required closeout order: headed full journey, deterministic light/dark parity
  for every referenced state, then `node tool/verify/run.mjs`.

A state-only widget/golden/parity capture is insufficient. If the complete path
or its terminal outcome is not implemented, or a business↔design conflict is
unresolved, keep the UI work In Progress/Blocked.

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

All verification uses the canonical entry point:

```text
node tool/verify/run.mjs             # full gate
node tool/verify/run.mjs --docs      # documentation/contract changes
node tool/verify/run.mjs --quick     # inner loop
node tool/verify/run.mjs --quick --test <path>
```

The verifier owns documentation/link/ID checks, design-audit validation, the
MemoX guard, code generation when required, formatting, analyze and tests. Do
not replace the final gate with loose commands because only the canonical entry
emits `.dart_tool/memox_verify_pass.json`.

Pull-request CI uses the two-tier policy in `docs/ci.md`: parallel contracts and
affected non-visual Flutter checks report the required `CI Gate`, while the full
Windows canonical gate runs nightly, manually, or when the PR has `full-ci`.
This optimization does not weaken the local completion rule above: code and UI
work still requires the full canonical verifier before handoff.
