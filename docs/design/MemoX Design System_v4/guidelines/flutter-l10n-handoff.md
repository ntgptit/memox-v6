# Flutter localization handoff — English and Vietnamese v1

> Owner: Design System + Localization · Status: Current · Decision date: 2026-07-18

The production source is `lib/l10n/*.arb` and generated `AppLocalizations`. The JSX catalog is a
prototype corpus only. Every design string maps to an ARB key before its WBS item is Ready.

## Required namespaces

| Namespace | Owns |
| --- | --- |
| `common.*` | Retry, Cancel, Continue, Back, Save and shared status labels |
| `deck.*`, `flashcard.*` | exclusive Deck-kind choices, list/editor/validation and transfer copy |
| `study.entry.*` | New learning, Due review, Relearn and Practice entry labels |
| `study.mode.*` | Review, Match, Guess, Recall, Fill and mode-specific outcomes |
| `study.session.*` | progress, pause/resume, persistence/finalization failures |
| `srs.*` | fixed policy id, boxes, intervals, due and mastered labels |
| `today.*` | loaded, paused, offline, partial, error, empty and caught-up states |
| `settings.*` | preference labels; SRS informational/read-only copy |

## Mapping rules

- English and Vietnamese key sets are identical; missing or extra keys fail the localization gate.
- Use placeholders for counts, Deck/card names and durations. Never concatenate count+noun text.
- ARB metadata documents placeholder type and screen/semantic owner.
- Relative/date/number values are formatted from locale-aware values, not preformatted repository
  strings. `dueAt` remains an instant and is formatted only at the UI boundary.
- Accessibility labels, tooltip copy, error announcements and notification text are localized.
- Study content is not translated by the UI catalog and carries its own language/direction.

## Required stress evidence

For both `en` and `vi`, verify 200% text at compact 320, medium 600 and expanded 840 boundaries.
Minimum screens: first run, Deck creation, Flashcard editor, Mode Picker, all five study modes,
Recall timeout, session recovery/finalize, Today paused/offline/partial/error and Settings SRS.

RTL is not a v1 shipping locale. New widgets still use directional APIs and logical leading/trailing
so enabling an RTL ARB locale later does not require renaming frozen ids or components.
