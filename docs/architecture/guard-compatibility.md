# Guard compatibility baseline

- Status: **Accepted contract; activation debt tracked by WBS 1.8**
- Owner: Architecture / Guard
- Updated: 2026-07-25

## Resolved drift

- Active import examples use the package namespace `package:memox_v6/...`.
- Retired Folder/Subfolder domain targets and examples use the canonical Deck/Library paths and
  vocabulary.
- SRS transition math is permitted only in
  `lib/domain/learning_progress/srs_8_box_policy.dart`; repository/data code may persist and call the
  policy but may not duplicate its transition logic.
- The `ci` profile treats warnings as errors and is covered by regression tests.

The guard lives in the `tools/code-verification-guard` submodule. Its changes must be committed in
that repository and the parent submodule pin updated together before they are published.

## Current activation boundary

The Flutter app is still a starter scaffold. The local profile therefore reports planned-path and
rule-without-target warnings for architecture files that do not exist yet. These warnings are not
evidence that the rules executed against those future files.

WBS 1.8 closes the activation debt by:

1. Creating each approved canonical source path through its owning foundation item.
2. Removing or correcting any target that remains stale after the source layout exists.
3. Running the full guard regression suite and the app verifier.
4. Switching CI/hooks from `local` to `ci` only when the warning count is zero or every remaining
   warning has a time-bounded owner-approved exception.

No rule may be weakened merely to make the scaffold green.

## Dormant-rule audit, 2026-07-25

Ten `memox.*` rules were reporting `rule_without_targets` on every run, which
means ten things nobody was checking. Audited each against the layout the
project actually has.

**Repointed and now live** (`code-verification-guard-v2#4`), all passing
against the current tree, so they lock in conventions that were being followed
by habit rather than enforced:

| Rule | Was scoped to | Actually lives in |
| --- | --- | --- |
| `architecture.drift_database_off_main_isolate` | `lib/data/datasources/local/**` | `lib/core/database/**` — the executor is not under `data/` at all |
| `layer_naming.dao_file_suffix` | `lib/data/datasources/local/daos/**` | `lib/data/database/daos/**` |
| `layer_naming.dao_class_suffix` | same | same |

**Repointed separately** (`code-verification-guard-v2#3`):
`performance.retained_async_state_requires_skeleton`, which named two renamed
paths and an API (`MxRetainedAsyncState`) the app does not have.

**Restated rather than repointed** (`code-verification-guard-v2#4` and `#5`) —
these could not be fixed by editing a path, because the defect was in what the
rule was asking, not where it looked:

| Rule | The actual defect | How it was restated |
| --- | --- | --- |
| `layer_naming.repository_interface_file_suffix` / `_class_suffix` | assumed a dedicated `lib/domain/repositories/**`; this repo keeps each port beside its aggregate, so there was no folder to scope to | read backwards: scan all of `lib/domain/**` *except* `*_repository.dart` and flag any `abstract interface class …Repository` found there. Same intent, no folder needed |
| `architecture.centralized_shared_preferences_provider` | scoped to `core_di` (= `lib/app/di/**`) and then excluded `lib/app/di/*_providers.dart` — every file there matches that exclude, so the rule erased its own scope | scoped to `dart_lib` minus the app DI. A ban on calling something *outside* one place must look everywhere but that place |
| `action_density.no_large_button_in_card_surface` | inherited from memox-v4: matched `MxButtonSize.large`, but v6's enum is `sm \| md \| lg`. Its scope also listed `*_card/_list/_tile.dart` and a `features/dashboard/`, none of which exist here | pattern now `MxButtonSize.lg`; scope gained `*_row.dart`, the suffix MemoX actually uses (`deck_summary_row.dart` renders `MxDeckCard`) |

**Left dormant on purpose — each needs a decision, not a path:**

| Rule | Why it cannot simply be repointed |
| --- | --- |
| `layer_naming.migration_file_prefix` | expects one file per schema version (`v8_*.dart`); this repo uses a single `app_migrations.dart`. Repointing would fail the build on a structural choice, not a naming slip. |
| `coding.flashcard_editor_no_part_of` | names a screen that no longer exists. |

**Disabled outright:** `action_density.no_full_width_button_in_card_surface`
matched a `fullWidth` parameter that appears nowhere in `lib/` — v6 lets the
parent's layout decide width. Left `enabled: true` it would report
`rule_without_targets` forever, which reads like coverage while enforcing
nothing; `enabled: false` with a reason is the honest state. Re-enable if
`MxButton` ever gains an explicit full-width affordance.

### Why a dormant rule is worse than no rule

None of these fifteen fixes changed a line of production code — the tree already
complied with every one. That is exactly why the outage lasted: a rule whose
scope matches no file **does not fail**. It emits a warning and passes. Every
verifier run in this branch's history printed those warnings, and they were read
past, because a green gate below them said the code was fine. Only the count of
warnings distinguished "fifteen rules enforcing" from "fifteen rules asleep".

When a rule's scope is edited, re-run the guard and confirm the
`rule_without_targets` count went *down*. A rule is enforcing only when it has
targets.


## Stale blockers, 2026-07-26

The dormant-rule audit has a sibling. A `Blocked — needs X` note is a claim
about a moment, and it keeps reading as current long after `X` ships. Nothing
re-checks it, so the row stays parked and the state stays unmeasured.

`MX-VIS-034` sat at "Blocked — add-card CTA enabled (5.3.2); measured 9.68% /
13.58%". `5.3.2` child A shipped that CTA; the row was never revisited, and the
state had **no parity spec at all**, so nothing would ever have re-measured it.
Written and measured on 2026-07-26: **1.50% light / 2.08% dark**. It had been
passing, unnoticed, for as long as the CTA had existed.

The check is cheap and worth repeating whenever a WBS row closes: list every
unmeasured `MX-VIS-*`, pull the WBS ids out of its status, and ask whether
those ids are still open. `tool/verify/parity_census.mjs` guarantees each row
*says* something; it cannot tell whether what it says is still true.
