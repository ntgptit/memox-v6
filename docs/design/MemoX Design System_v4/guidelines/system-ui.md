# System-UI appearance — status bar & system navigation bar

> Closes audit item **KIT-34-05** (no spec for status-bar icon mode by light/dark surface,
> and no system nav-bar appearance statement per theme).

Defines how the OS chrome that MemoX does **not** draw — the **status bar** (top) and the
Android **system navigation bar** (bottom) — must appear in each theme, so the OS glyphs
stay legible against the surface directly behind them. Additive documentation only: this
maps existing surface tokens to a `StatusBar` / system-UI configuration; it introduces no
token/`Mx*`/class names and changes no rendered kit pixels (the kit does not render OS
chrome; this governs the RN runtime).

Owner: Design System team · Status: Current (v4, additive-only).

---

## 1. Principle — icons contrast with the surface behind them

The status-bar and nav-bar glyphs are drawn by the OS in one of two modes: **dark icons**
(for use over a *light* surface) or **light icons** (for use over a *dark* surface). Pick
the mode by the **luminance of the MemoX surface immediately behind the bar**, not by a
fixed value. Because MemoX ships one visual language on both platforms (see `SCOPE.md`),
the mode is chosen by theme + the surface token under the bar, identically on iOS and
Android.

- **Rule:** light surface behind the bar → **dark** OS icons. Dark surface → **light** OS
  icons. The bar's own fill matches the surface token behind it so there is no seam.

---

## 2. Status bar (top) — mode by theme

The status bar sits above `--memox-safe-area-top` over the app-bar / top surface.

| Theme | Surface behind status bar | Status-bar **icon mode** | iOS `StatusBar barStyle` | Android `StatusBar` | Bar background |
| --- | --- | --- | --- | --- | --- |
| **Light** (`:root`) | `--memox-bg` #f6f5fc / `--memox-surface` #ffffff | **Dark icons** | `dark-content` | `barStyle="dark-content"`, `setBarStyleAsync('dark')` | Translucent over the top surface token (no opaque band) |
| **Dark** (`[data-theme='dark']`) | `--memox-bg` #141220 / `--memox-surface` #252338 | **Light icons** | `light-content` | `barStyle="light-content"`, `setBarStyleAsync('light')` | Translucent over the top surface token |

- **Translucent, not painted:** the status bar is `translucent` so content scrolls under it;
  the reserved space is `--memox-safe-area-top` (`max(env(safe-area-inset-top), 24px)`).
- **Over a colored hero / immersive header:** choose the mode from *that* surface's
  luminance, not the theme. A deep-violet `--memox-primary` (#4b3a8c) header is a dark
  surface → **light** icons in both themes.
- **Overlays:** when a sheet/dialog scrim (`--memox-scrim`) darkens the whole screen, the
  status bar reads over the scrim → **light** icons while the overlay is open, restored on
  close (see `navigation-overlays.md`).

## 3. System navigation bar (Android bottom) — mode by theme

Android draws a bottom system nav bar (gesture pill or 3-button) below the MemoX
`MxBottomNav`. Its buttons follow the same surface-contrast rule.

| Theme | Surface behind nav bar | Nav-bar **button mode** | Android config | Bar background |
| --- | --- | --- | --- | --- |
| **Light** | `--memox-surface` #ffffff (bottom-nav surface) | **Dark buttons** | `NavigationBar.setButtonStyleAsync('dark')` | `--memox-surface` #ffffff |
| **Dark** | `--memox-surface` #252338 | **Light buttons** | `NavigationBar.setButtonStyleAsync('light')` | `--memox-bg`/`--memox-surface` dark tone |

- The nav-bar background token must equal the bottom-nav surface behind it so the OS bar
  and `MxBottomNav` read as one band; `--memox-safe-area-bottom`
  (`max(env(safe-area-inset-bottom), --memox-comp-nav-safe-pad)`) reserves the inset.
- iOS has no system nav bar; only the home-indicator inset applies, covered by the same
  bottom safe-area token.

## 4. Where this is set (RN runtime)

- Configure once via `expo-status-bar` (`<StatusBar style="auto" />` resolves the mode from
  the active theme surface) and `expo-navigation-bar` for Android, driven off the same
  `data-theme` switch the tokens use. See the Expo v57 docs before wiring.
- **Reduced motion:** bar style changes are instantaneous (no animated tint); honour
  `--memox-duration-none` where a transition would otherwise apply.
- **Verification:** on each theme, confirm status-bar glyphs and Android nav buttons are
  legible against the surface behind them (contrast ≥ 3:1). This is a manual OS-chrome
  check — the kit's 390×780 shots exclude OS chrome by design, so it is not part of the
  pixel-parity gate.
