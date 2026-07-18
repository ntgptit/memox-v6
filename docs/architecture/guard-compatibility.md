# Guard compatibility baseline

- Status: **Accepted contract; activation debt tracked by WBS 1.8**
- Owner: Architecture / Guard
- Updated: 2026-07-18

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
