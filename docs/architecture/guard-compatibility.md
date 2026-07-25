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

**Left dormant on purpose — each needs a decision, not a path:**

| Rule | Why it cannot simply be repointed |
| --- | --- |
| `layer_naming.repository_interface_file_suffix` / `_class_suffix` | assume a dedicated `lib/domain/repositories/**`. This repo keeps each interface beside its aggregate, per the AGENTS.md rule against per-feature triplets, so there is no folder to scope to and a `lib/domain/**` scope would fail every model file. The rule needs to key off file content. |
| `layer_naming.migration_file_prefix` | expects one file per schema version (`v8_*.dart`); this repo uses a single `app_migrations.dart`. Repointing would fail the build on a structural choice, not a naming slip. |
| `coding.flashcard_editor_no_part_of` | names a screen that no longer exists. |
| `architecture.centralized_shared_preferences_provider`, both `action_density.*` | carry no include block at all — a different defect from a stale path. |

The submodule pointer is not bumped until those two PRs are reviewed: the guard
is shared with other consumers, so activating rules for everyone is not a
side effect this repo should cause on its own.
