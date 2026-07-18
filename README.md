# MemoX v6

MemoX v6 is a local-first spaced-repetition study app built with Flutter.

## Release platform priorities

- **Tier 1:** Web and Android.
- **Roadmap:** iOS, Windows, macOS and Linux.
- Tier 1 includes responsive web layouts, Android phone/tablet/landscape, and
  keyboard/mouse/focus behavior where the platform exposes those inputs.

The runtime is currently a greenfield Flutter scaffold. Product and technical
contracts are being completed before feature implementation begins.

## Documentation sources of truth

- [Documentation portal](docs/README.md)
- [Business capability catalog](docs/business/README.md)
- [MemoX Design System v4](docs/design/MemoX%20Design%20System_v4/readme.md)
- [Architecture decisions](docs/architecture/README.md)
- [Database and migration contract](docs/database/README.md)
- [Decision tables](docs/decision-tables/README.md)
- [Delivery WBS](docs/wbs/memox-v6-development-wbs.md)
- [Traceability register](docs/traceability/README.md)
- [Code Verification Guard](docs/code-verification-guard.md)

If Business and Design disagree, stop and resolve the conflict through the
decision register before implementing either interpretation.

## Setup

```text
git submodule update --init --recursive
python -m pip install -r tools/code-verification-guard/requirements.txt
flutter pub get
```

Enable repository hooks once per clone:

```text
git config core.hooksPath .githooks
```

## Verification

Use the single repository entry point:

```text
node tool/verify/run.mjs
```

Useful scoped modes:

```text
node tool/verify/run.mjs --docs
node tool/verify/run.mjs --quick
node tool/verify/run.mjs --quick --test test/path_test.dart
```

The verifier checks documentation links/IDs, the design checklist, the MemoX
guard, required code generation/formatting, analysis and tests, then writes a
gitignored pass marker under `.dart_tool/`.
