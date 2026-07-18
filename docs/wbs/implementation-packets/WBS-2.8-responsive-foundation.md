# WBS 2.8 — Responsive foundation implementation packet (XL)

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) — children A–C complete |
| Owner/domain | Design System + Flutter UI / Responsive |
| Depends on | `2.7` — Done |
| Decision gates | DG-02 (ADR-002 window matrix) |
| Acceptance | `AC-WBS-2.8-01` |
| Test | `TEST-WBS-2.8-01` |

## Canonical inputs

- WBS §5.3 responsive contract: width classes and required test widths —
  compact-mobile `<430` (320/360/390/412), compact `<600` (599), medium
  `600–839` (600/768/839), expanded `840–1199` (840/1024/1199), large
  `≥1200` (1200/1440/1920). Branch by available window width, never by
  device label or orientation (Flutter adaptive best practices).
- Kit `spacing.css` layout roles: gutter 16 / gutter-medium 24 /
  gutter-expanded 32; content-width caps reading 640 / study 720 /
  list 1200 / dashboard 1280.
- Guard expected path `lib/core/theme/responsive/app_breakpoints.dart`
  (already referenced by `no_theme_token_imports` excludes).

## Child boundaries (XL rule)

| Child | Boundary | Status |
| --- | --- | --- |
| A | Screen classes: `AppBreakpoints`, `ScreenClass.fromWidth`, `ScreenInfo`, `context.screenClass`/`context.screenInfo`; boundary tests at every §5.3 width | **Done** (2026-07-19) |
| B | Adaptive family values: per-class gutters + compact-mobile density flag (`context.spacing`), kit content-width caps + navigation-container rule (`context.layout`) | **Done** (2026-07-19) |
| C | Grid/pane rules (list/detail thresholds), `context.component` adaptive values (grounded in the Mx component specs they serve), resize/state-restoration tests across class transitions | **Done** (2026-07-19) |

Boundary note: `context.component` moved from B to C so its values are
grounded in real component consumers instead of invented ahead of the `Mx*`
specs (3.x); §5.3 contract coverage is unchanged.

## Scope — child A (this delivery)

Create:

- `lib/core/theme/responsive/app_breakpoints.dart` — boundary constants
  (430/600/840/1200), `ScreenClass` enum (compactMobile/compact/medium/
  expanded/large) with `fromWidth`, immutable `ScreenInfo` (width + class +
  convenience flags), and the `AppResponsiveContext` extension
  (`context.screenClass`, `context.screenInfo`) reading
  `MediaQuery.sizeOf` so only width changes rebuild consumers.
- `test/core/theme/responsive/app_breakpoints_test.dart` — pure
  `fromWidth` boundary table (all 14 §5.3 widths plus exact boundary
  edges) and a widget test resolving the class through `MediaQuery` at
  every required width.

Out of scope for child A: adaptive values/gutters (B), pane rules and
resize tests (C), navigation rail switching (3.6), window-size E2E
(`MEMOX_E2E_WINDOW_SIZE`, 5.7.4).

## Acceptance and test procedure

`AC-WBS-2.8-01` (child A portion) is true only when:

1. Class boundaries match WBS §5.3 exactly, exclusive upper bounds
   (429.9 → compactMobile, 430 → compact, 600 → medium, 840 → expanded,
   1200 → large).
2. Consumers read the class only through the context extension; no
   feature imports of the breakpoints file (guard scope).
3. Every §5.3 required width resolves to its documented class in both the
   pure and MediaQuery-driven tests.
4. Full canonical gate passes.

`TEST-WBS-2.8-01` (child A portion):
`test/core/theme/responsive/app_breakpoints_test.dart` in every gate. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Child B promotion requires child A merged and green; the WBS `2.8` row
  stays Ready until child C completes, then flips Done with all evidence.
