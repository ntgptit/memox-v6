# Release readiness & sign-off record

## Release under review

- Kit: MemoX Design System v4, rebaseline targeting v4.1
- Product decision date: 2026-07-18
- Tier 1: Flutter Web and Android
- Current status: **🔴 BLOCKED**

The Product Owner resolved the platform, Deck, session, Mode Picker, Guess, Recall, SRS and locale
decisions. Their design contracts and reference sources have been rebaselined. Release remains
blocked because the current repository has no runnable design screenshot/parity/a11y toolchain and
there is no Tier-1 medium/expanded/landscape/Web-keyboard evidence.

## Gates

| Gate | Requirement | Status | Evidence |
| --- | --- | --- | --- |
| Product decisions | All Business↔Design P0 choices ratified and reflected | ✅ Contract fixed | `SCOPE.md`; affected JSX/specs |
| Frozen contract | no token, `Mx*` or active `data-mx-node` rename | ✅ Preserved | additive tokens; deprecated `convert-*` fail closed |
| Structural audit | checklist links/IDs/format validate | ✅ Pass (2026-07-18) | `mobile-design-kit-audit-v5/validation-report.json`; canonical docs verifier |
| Web responsive | compact/medium/expanded boundary evidence | ❌ Open P1 | `coverage-report.md` |
| Android adaptive | phone/tablet, portrait/landscape, IME/Back evidence | ❌ Open P1 | `coverage-report.md` |
| Keyboard/pointer | current Flutter Web task walkthrough | ❌ Open P1 | no current runtime evidence |
| Changed study/UI states | Deck, Mode Picker, Recall timeout, SRS Settings, Today recovery shots | ❌ Open P1 | source/spec updated; new shots absent |
| English/Vietnamese | complete ARB parity + 200% runtime evidence | ❌ Open P1 | `guidelines/flutter-l10n-handoff.md` |
| Open P0/P1 | zero | ❌ Open P1 remains | `mobile-design-kit-audit-v5/issue-register.md` |

Unavailable historical `npm`, parity, contrast and screenshot commands are not counted as passing.

## Sign-off

| Role | Owner | Decision | Date | Re-open condition |
| --- | --- | --- | --- | --- |
| Design owner | Design System team | **Not approved** | 2026-07-18 | Tier-1 visual/adaptive state matrix attached |
| Accessibility owner | Accessibility reviewer | **Not approved** | 2026-07-18 | current Flutter Web/Android a11y evidence passes |
| Governance owner | Documentation/Design governance | **Not approved** | 2026-07-18 | zero P0/P1 and reproducible verification commands |

Approval requires all three rows to be Approved, zero open P0/P1, and evidence linked to exact
platform/profile/locale/theme/state. Documentation completion alone cannot clear the release.
