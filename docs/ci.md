# Continuous integration

MemoX uses a two-tier CI pipeline so pull requests receive useful feedback in
about two minutes without deleting the full Windows regression gate.

## Required pull-request gate

Every pull request reports one stable required check named `CI Gate`. It combines:

- `Contracts and architecture` on Ubuntu: documentation inventory, design audit,
  token manifest, CI-scope regression tests, guard regression tests and the MemoX
  code guard;
- `Flutter fast gate` on Ubuntu for non-doc changes: dependency resolution, l10n,
  code generation, formatting, analysis and affected non-visual tests.

The jobs run in parallel. Text-only Markdown changes skip Flutter setup. The scope
selector is `tool/verify/ci_scope.mjs`; unknown or shared paths fail safe to every
non-visual Flutter test rather than selecting no tests.

After a merge, `Warm fast-gate cache` runs on Ubuntu and only refreshes Pub, l10n
and incremental build-runner state. It does not repeat analysis or tests. Pull
requests can restore this default-branch cache, keeping clean-runner setup inside
the fast-gate budget.

Golden and kit-parity widget tests are intentionally excluded from Ubuntu because
their frozen comparison host is Windows. They remain part of the full canonical
gate.

## Full canonical gate

`Full Canonical (Windows)` runs `node tool/verify/run.mjs` and therefore retains
all repository checks and all Flutter tests, including golden and parity tests. It
runs:

- nightly at `18:00 UTC` (`03:00` Asia/Seoul);
- from `workflow_dispatch`;
- on a pull request carrying the `full-ci` label.

Use `full-ci` before merge for changes to golden baselines, parity infrastructure,
Flutter/SDK versions, generated-code infrastructure, database schemas or any
change whose risk is not represented by the affected-test mapping.

## Local verification remains canonical

The optimized PR gate does not replace local completion evidence. Code and UI
work still finishes with:

```text
node tool/verify/run.mjs
```

Use `--docs` for documentation-only work, `--quick` for an inner loop, and
`--flutter-fast --base <revision> --head <revision>` only when reproducing the CI
Flutter job. `--warm-cache` is CI plumbing and deliberately emits no verification
marker.

## Branch protection

Protect `main`, require pull requests, disallow direct pushes and require the
single `CI Gate` status. The `push: main` workflow only refreshes reusable build
state; it must never be treated as verification evidence.
