# WBS 1.1 — Dependency baseline implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Platform + QA / Bootstrap tooling |
| Depends on | `0.4` — Done |
| Decision gates | DG-02, DG-05, DG-06 |
| Acceptance | `AC-WBS-1.1-01` |
| Test | `TEST-WBS-1.1-01` |

## Canonical inputs

- `pubspec.yaml`, `pubspec.lock`, Dart SDK constraint `^3.11.5`.
- `docs/architecture/adr/ADR-002-platform-and-adaptive-scope.md`.
- `docs/architecture/adr/ADR-004-local-persistence-platforms.md`.
- `docs/architecture/adr/ADR-005-bootstrap-and-error-boundary.md`.
- `docs/architecture/adr/ADR-006-navigation-contract.md`.
- `docs/architecture/adr/ADR-007-riverpod-and-testing.md`.
- `docs/database/README.md` and `docs/code-verification-guard.md`.

## Scope

Modify:

- `pubspec.yaml`: declare the approved direct dependency families below.
- `pubspec.lock`: regenerate only through the canonical full verifier.
- `docs/traceability/work-item-register.md`: record completion evidence and
  change `1.1` to Done only after the gate passes.

Do not create application source, providers, routes, tables or models in this
item. Do not edit generated localization or Dart generator output.

## Approved direct dependency manifest

| Role | Dependency | Constraint decision |
| --- | --- | --- |
| Flutter/Riverpod runtime | `flutter_riverpod`, `riverpod_annotation` | Preserve the existing compatible 3.2.1 / 4.0.2 line |
| Riverpod generator | `riverpod_generator`, `build_runner` | Preserve existing generator/build constraints |
| Routing | `go_router` | `^17.3.0`; constants/wrappers remain owned by WBS 1.4 |
| Persistence runtime | `drift`, `drift_flutter` | `^2.34.2`, `^0.3.1`; shared Web/Android opener owned by WBS 4.1 |
| Persistence generator | `drift_dev` | **Deferred to the WBS 4.1 packet** (analyzer/meta evidence below) |
| Immutable/JSON runtime | `freezed_annotation`, `json_annotation` | compatible caret constraints resolved with current SDK |
| Immutable/JSON generator | `freezed`, `json_serializable` | dev dependencies compatible with annotation packages |
| Determinism | `clock`, `timezone`, `uuid` | compatible caret constraints; concrete ports/fakes owned by WBS 1.6 |
| Testing | `mocktail`, `fake_async`, Flutter SDK `integration_test` | dev dependencies; harness owned by WBS 1.10 |

Version policy:

- Exact transitive resolution is frozen by committed `pubspec.lock`.
- No `any`, git or path dependency.
- Do not add file picker, notification, audio, account, sync, backup or analytics
  packages before their owning slice becomes Ready.
- If the listed direct constraints cannot resolve under SDK `^3.11.5`, stop
  and update this packet with compatibility evidence; do not silently replace
  the architecture package.

The routing and Drift versions were checked against their official pub.dev
package records on 2026-07-19. A later implementation date must re-check only
compatibility/security, not automatically chase a newer major.

Analyzer compatibility evidence (pub.dev + local toolchain, 2026-07-19), on
Flutter 3.41.7 stable / Dart 3.11.5, where the SDK's `flutter_test` pins
`meta 1.17.0`:

- `riverpod_generator` stable line supports only analyzer `^9` (4.0.1–4.0.3)
  or `^12` (4.0.4); no version supports analyzer 10, 11 or 13.
- `drift_dev` requires analyzer `>=10 <13` (2.32.1–2.34.0) or `^13` (≥2.34.1).
- Every analyzer release ≥10.0.2 (including all of 11, 12, 13) requires
  `meta ^1.18`, which conflicts with the SDK-pinned `meta 1.17.0`.

Therefore no (`riverpod_generator`, `drift_dev`) pair co-resolves on the
pinned SDK. Accepted resolution: keep the Riverpod line and the `drift`/
`drift_flutter` runtime unchanged, and defer `drift_dev` to the WBS 4.1
packet, which owns the first generated Drift code. That packet must re-check
this evidence (a newer `riverpod_generator` supporting analyzer `^13`, or an
approved Flutter SDK upgrade shipping `meta ≥1.18`, unblocks it).

## Acceptance and test procedure

`AC-WBS-1.1-01` is true only when:

1. Every manifest dependency is in the correct runtime/dev section.
2. `pubspec.lock` resolves reproducibly with no disallowed source or `any`.
3. Existing Riverpod generator/runtime constraints remain compatible.
4. No capability dependency outside this packet is introduced.
5. The starter app still compiles/analyzes/tests through the canonical gate.

`TEST-WBS-1.1-01`:

- Run `node tool/verify/run.mjs` once after the manifest edit. Do not run loose
  `flutter pub get`, codegen, analyze or tests.
- Review the verifier's pub-get, build-runner, format, guard, analyze and Flutter
  test results.
- Review `git diff -- pubspec.yaml pubspec.lock`; unexpected transitive source,
  SDK downgrade or platform plugin is a failure.
- Fixtures: existing starter app only; no database/provider fixture belongs here.

## Failure and completion

- Resolution failure: keep `1.1` Ready, attach the conflict, and do not modify
  downstream source.
- Gate failure: fix the dependency/root cause; never weaken guard/analyzer.
- Success: add verifier marker/report path to the register, mark `1.1` Done,
  then assess `1.3`, `1.4` and `1.9` independently for Ready promotion.
