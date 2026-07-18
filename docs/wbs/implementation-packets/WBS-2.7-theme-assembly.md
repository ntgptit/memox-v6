# WBS 2.7 — Theme assembly implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme |
| Depends on | `2.6` — Done |
| Decision gates | DG-02 |
| Acceptance | `AC-WBS-2.7-01` |
| Test | `TEST-WBS-2.7-01` |

## Canonical inputs

- Token + extension layers (2.2–2.6).
- Kit contracts: flat app bar at 56dp on the canvas color, M3 FAB 56 with
  accent fill, neutral snackbar ground tokens, hairline dividers,
  interaction-state layers, dark-mode canvas `#141220`.
- Guard: `theme_file_no_riverpod` (this file is definitions-only).

## Scope

Create:

- `lib/core/theme/app_theme.dart` — `AppTheme.light()/dark()`:
  - Full M3 `ColorScheme` built from semantic tokens with a **documented
    mapping table** (primary/secondary/tertiary/error families, surface
    containers from muted/raised/sunken, outline from border tokens, scrim
    from overlay, inverse slots from the opposite theme). The scheme exists
    so plain Material internals render on-brand; `Mx*` widgets keep reading
    tokens via `context.colors`.
  - Global fields: scaffold/canvas bg, divider, focus/hover/highlight/
    splash/disabled from the state-layer tokens, primary font family.
  - Component themes with explicit kit contracts: `AppBarTheme` (56dp,
    flat, canvas bg, per-theme `SystemUiOverlayStyle`), `DividerTheme`
    (hairline), `FloatingActionButtonTheme` (56, accent/onAccent,
    radius-lg), `SnackBarTheme` (neutral ground tokens, floating, hairline
    border, accent action), `ProgressIndicatorTheme` (accent on sunken
    track).
  - Theme extensions (colors/elevations/text styles) attached per theme.
  - `systemUiOverlayStyle(brightness)` — transparent status bar with
    theme-correct icon brightness; nav bar on the canvas color.

Modify:

- `lib/app/app.dart` — `theme: AppTheme.light()`, `darkTheme:
  AppTheme.dark()`, `themeMode: ThemeMode.system` (runtime mode; the
  persisted appearance preference is WBS 8.1).

- `test/core/theme/app_theme_test.dart` — scheme-slot parity per theme,
  component-theme contracts, overlay styles, font application, and a
  runtime platform-brightness switch test through the real app root.

Out of scope: persisted theme preference (8.1), high-contrast profile
(2.9), responsive foundation (2.8), Mx component themes beyond the
Material defaults listed (3.x own their widget styling).

## Acceptance and test procedure

`AC-WBS-2.7-01` is true only when:

1. Both ThemeData instances derive every color from tokens (no ad-hoc
   values beyond the documented transparent/shadow constants).
2. The mapping table in code matches the tests slot-for-slot.
3. System UI appearance is theme-correct and wired through the app bar.
4. The app switches themes with platform brightness at runtime.
5. Full canonical gate passes.

`TEST-WBS-2.7-01`: `app_theme_test.dart` (6 tests) in every gate. Run once
through `node tool/verify/run.mjs`.

## Failure and completion

- Success: record register evidence, mark `2.7` Done, then author `2.8`
  (responsive foundation, XL — child boundaries required) next.
