# Study-wave domain — overnight autonomous run

Branch: `feat/study-domain` (off `main` @ 0558139). Scope: non-UI / domain /
data / policy WBS packages only (STOP RULE gates all UI until P0.6). One
package = one gate-verified commit. Stops on: gated UI, spec ambiguity /
owner decision needed, or a gate that won't go green.

Spec sources: `docs/business/learning-progress/**`,
`docs/decision-tables/srs-8-box-v1.md`, `docs/database/schema-v1.md`,
`docs/architecture/adr/**`.

---

## 5.4.1 — Initial progress · ✅ DONE (gate green)

**DoD:** idempotent New state and repair behavior; no orphan progress.

**Scoping finding:** the *create* path is already done under 5.3.1 —
`DriftFlashcardRepository.createFlashcard` inserts the initial Box-0 progress
atomically with the card. 5.4.1's remaining, distinct deliverable is the
**idempotent ensure / safe-repair** operation (`initialise-card-progress.md`
§§2,5): a card missing its progress row (import, backup restore, data repair)
gets a New state; a duplicate initialise returns the same state without
resetting a learned card; a missing card creates no orphan (the `learning_progress.card_id`
FK enforces this). New state per the spec + SRS Policy v1: `box = 0`,
`dueAt = null`, `policyId = leitner-8-box-v1`, no Attempt.

**Built:** `learning_progress.drift` idempotent `initialiseCardProgress` (INSERT
OR IGNORE, Box 0 / NULL due); `LearningProgressRepository.ensureInitialProgress`
(returns existing untouched, else creates New, FK prevents orphan);
`InitialiseCardProgressUseCase` + provider. Tests: repair→New, idempotent
no-reset (Box 5 preserved), no-orphan for a missing card. Full gate green.

**Next:** 5.4.2 — Due/new/relearn query policy.
