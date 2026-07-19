# Code Verification Guard

`memox_v6` uses [code-verification-guard-v2](https://github.com/ntgptit/code-verification-guard-v2)
as its **main code guard**. It scans the project against the `memox` ruleset
(YAML rules for design-system, i18n, architecture, file layout, etc.) and blocks
non-compliant code at three points: git pre-commit, CI, and the Claude Code agent.

The guard is vendored as a **git submodule** at `tools/code-verification-guard`.

## One-time setup (after cloning)

```bash
# 1. Fetch the guard submodule
git submodule update --init --recursive

# 2. Install the guard's Python dependencies (needs Python 3.12+)
python -m pip install -r tools/code-verification-guard/requirements.txt

# 3. Activate the shared git hooks (pre-commit guard + auto l10n regen)
git config core.hooksPath .githooks
```

Activating `.githooks` also enables `post-merge` / `post-checkout` hooks that
regenerate the localizations after a pull or branch switch. Locally, `generate: true`
in `pubspec.yaml` already regenerates them on `flutter pub get`, `run`, `build`,
and `test`; CI regenerates them explicitly with `flutter gen-l10n`.

## Running the guard manually

```bash
python tools/code-verification-guard/guard/run.py check --project . --ruleset memox --profile local
```

Exit code `0` = passed, `1` = violations found.

For normal repository work, use `node tool/verify/run.mjs` (or `--docs` /
`--quick`) instead. That canonical entry runs the guard in the correct order
with the other required gates and emits the verification pass marker.

## Where the guard runs

| Surface           | Config                       | Profile | Behavior                                        |
| ----------------- | ---------------------------- | ------- | ----------------------------------------------- |
| Git pre-commit    | `.githooks/pre-commit`       | `local` | Blocks the commit on errors. Bypass: `--no-verify` |
| CI (GitHub)       | `.github/workflows/ci.yml`   | `local` | Fails `Contracts and architecture` on errors    |
| Claude Code agent | `.claude/settings.json` (Stop hook) | `local` | Blocks turn completion on errors, feeds back violations |

### Profiles

- `local` — fails on **errors** only (warnings reported, not fatal). Current default.
- `ci` — treats **warnings as errors** too (stricter); this behavior is contract-tested in the guard submodule.
- `strict` — fails on errors **and** warnings.

Tighten CI / hooks to `ci` or `strict` once the codebase is built out and the
stale-path (`guard.config.missing_target_path`) warnings are resolved.

## MemoX v6 compatibility baseline

- The canonical Dart package namespace is `package:memox_v6/...`; active
  architecture, routing, design-system, observability and shared-widget rules
  must not match the retired `package:memox/...` namespace.
- SRS transition/interval logic belongs to the pure-domain policy at
  `lib/domain/learning_progress/srs_8_box_policy.dart`. Repositories own the
  atomic Attempt + Progress persistence boundary and call that policy; they do
  not own or duplicate the box-transition calculation.
- Rules that target planned source paths are not evidence that the path already
  exists. WBS foundation gate `1.8` must reconcile every active path and remove
  `rule_without_targets` / `missing_target_path` warnings before feature work is
  considered guard-ready.
- Guard compatibility decisions and activation debt are tracked in
  `docs/architecture/guard-compatibility.md`.

## Updating the guard

The guard is its own repository. Update the pinned version with:

```bash
cd tools/code-verification-guard
git fetch && git checkout <commit-or-tag>
cd ../..
git add tools/code-verification-guard
git commit -m "Bump code-verification-guard"
```

Do not edit files under `tools/code-verification-guard/**` from this repo — rule
changes belong in the guard repository itself.
