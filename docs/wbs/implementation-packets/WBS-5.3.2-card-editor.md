# WBS 5.3.2 — Card Editor packet (XL)

| Field | Value |
| --- | --- |
| Status | **In progress** — child A Done (2026-07-19); B, C pending |
| Owner/domain | Flashcard / Presentation |
| Depends on | `3.12` Done, `5.3.1` Done |
| Decision gates | DG-01 |
| Acceptance | `AC-WBS-5.3.2-01` |
| Test | `TEST-WBS-5.3.2-01` |

## Canonical inputs

- `create-flashcard.md` (form archetype, single Save primary, target
  deck context, atomic save + initial progress, duplicate resolution
  before commit), `edit-flashcard.md` (version-guarded save),
  `manage-card-translations.md` (nested section), kit
  `flashcard-editor` (10 states; deck-driven language labels;
  dirty-cancel guarded by discard-confirm; sticky Save;
  progressive disclosure).

## Child boundaries (one child per PR)

| Child | Scope |
| --- | --- |
| **A** | Create state: modal editor shell (close + centered title), deck-context pill, deck-driven term/meaning fields, tags input (resolve + attach on save), create-another toggle, atomic save via `CreateFlashcardUseCase`, validation state; "Add card" CTA activates on the empty deck; kit parity for `flashcard-editor--create` and (unblocked) `empty-deck--default` |
| **B** | Duplicate resolution (4-way review), submitting/submit-error/submit-success, dirty-discard confirm |
| **C** | Edit mode (stale-version), additional-translations section, audio row, keyboard/more-options states; stale-target handling |

## Acceptance and test procedure

`AC-WBS-5.3.2-01`: the editor creates learnable cards atomically in
the target deck with typed validation and duplicate review before
commit; drafts survive failure; every shipped state carries kit-parity
evidence (<3%) per the 3.15 rule.

`TEST-WBS-5.3.2-01`: widget + parity suites per child in every gate.

## Failure and completion

- Success per child: PR merged with the canonical gate green. 5.3.2
  flips Done when C merges; `5.3.3` (flashcard list) follows.
